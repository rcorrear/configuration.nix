(ns oathkeeper-smoke-fixture
  (:require [clojure.string :as str])
  (:import [java.io BufferedReader BufferedWriter InputStreamReader OutputStreamWriter]
           [java.net ServerSocket SocketException URI]
           [java.net.http HttpClient HttpRequest HttpResponse$BodyHandlers]
           [java.time Duration]))

(def identity-id "ory-smoke-identity")
(def email "smoke@example.test")
(def expires-at "2030-01-02T03:04:05Z")
(def ory-port 18080)
(def proxy-port 4455)
(def last-proxy-error* (atom nil))
(def ory-observations* (atom []))
(def upstream-port 18081)

(defn header-map
  [^BufferedReader reader]
  (loop [headers {}]
    (let [line (.readLine reader)]
      (if (str/blank? line)
        headers
        (let [[name value] (str/split line #":\s*" 2)]
          (recur (assoc headers (str/lower-case name) value)))))))

(defn write-response!
  [^BufferedWriter writer status body]
  (let [bytes (.getBytes body)]
    (.write writer (str "HTTP/1.1 " status " " (if (= status 200) "OK" "Rejected") "\r\n"))
    (.write writer "Content-Type: application/json\r\n")
    (.write writer (str "Content-Length: " (count bytes) "\r\nConnection: close\r\n\r\n"))
    (.write writer body)
    (.flush writer)))

(defn start-server
  [port handler]
  (let [server  (ServerSocket. port)
        running (atom true)
        worker  (future
                  (while @running
                    (try
                      (with-open [socket (.accept server)
                                  reader (BufferedReader. (InputStreamReader. (.getInputStream socket)))
                                  writer (BufferedWriter. (OutputStreamWriter. (.getOutputStream socket)))]
                        (let [request-line (.readLine reader)
                              [_ path]     (str/split (or request-line "") #"\s+" 3)
                              {:keys [status body]} (handler {:headers (header-map reader) :path path})]
                          (write-response! writer status body)))
                      (catch SocketException _ nil))))]
    {:stop #(when (compare-and-set! running true false)
              (.close server)
              @worker)}))

(defn scenario
  [headers]
  (or (some->> (get headers "cookie")
               (re-find #"(?:^|;\s*)smoke=([^;]+)")
               second)
      "missing"))

(defn session-json
  [value]
  (let [active          (not= value "inactive-session")
        identity-active (not= value "inactive-identity")
        verified        (not= value "unverified")]
    (str "{\"active\":"
         active
         ",\"expires_at\":\""
         expires-at
         "\",\"identity\":{\"id\":\""
         identity-id
         "\",\"state\":\""
         (if identity-active "active" "inactive")
         "\",\"traits\":{\"email\":\""
         email
         "\"},\"verifiable_addresses\":["
         (if verified (str "{\"value\":\"" email "\",\"verified\":true,\"via\":\"email\"}") "")
         "]}}")))

(defn ory-handler
  [observations]
  (fn [{:keys [headers path]}]
    (let [value (scenario headers)]
      (swap! observations conj {:header-names (set (keys headers)) :path path :scenario value})
      (cond
        (or (not= path "/sessions/whoami") (#{"missing" "invalid" "revoked"} value))
        {:status 401 :body "{\"error\":\"rejected\"}"}

        (= value "error")
        {:status 500 :body "{\"error\":\"fixture\"}"}

        (= value "timeout")
        (do
          (Thread/sleep 3000)
          {:status 200 :body (session-json value)})

        :else
        {:status 200 :body (session-json value)}))))

(defn upstream-handler
  [requests]
  (fn [{:keys [headers]}]
    (swap! requests conj headers)
    {:status 200 :body "{\"ok\":true}"}))

(defn- request-to
  [value forged? path]
  (let [headers (cond-> {"Cookie" (str "smoke=" value)}
                  (= value "missing") (dissoc "Cookie")
                  forged? (assoc "Authorization" "Bearer forged"
                                 "X-Omni-Auth-Ory-Identity-Id" "forged-identity"))
        builder (doto (HttpRequest/newBuilder (URI/create (str "http://127.0.0.1:" proxy-port path)))
                  (.timeout (Duration/ofSeconds 2)))]
    (doseq [[name header] headers]
      (.header builder name header))
    (try
      (let [status (.statusCode
                    (.send (HttpClient/newHttpClient)
                           (.build (.GET builder))
                           (HttpResponse$BodyHandlers/ofString)))]
        (reset! last-proxy-error* nil)
        status)
      (catch Exception error
        (reset! last-proxy-error* (str (class error) ": " (.getMessage error)))
        nil))))

(defn request
  [value forged?]
  (request-to value forged? "/api/smoke"))

(defn request-with-query
  [value forged?]
  (request-to value forged? "/api/smoke?application=query"))

(defn assert-query-not-forwarded!
  []
  (let [before      (count @ory-observations*)
        status      (request-with-query "valid" false)
        observation (last @ory-observations*)]
    (when-not (and (= 200 status)
                   (= (inc before) (count @ory-observations*))
                   (= "/sessions/whoami" (:path observation)))
      (throw (ex-info "Application query reached Ory session endpoint."
                      {:last-ory-observation observation :status status})))
    (println (str "query: status=" status " ory-path=" (:path observation)))))

(defn wait-for-proxy!
  []
  (let [deadline (+ (System/currentTimeMillis) 20000)]
    (loop []
      (cond
        (some? (request "missing" false))
        nil

        (> (System/currentTimeMillis) deadline)
        (throw (ex-info "Oathkeeper proxy did not become reachable."
                        {:last-proxy-error @last-proxy-error*}))

        :else
        (do
          (Thread/sleep 200)
          (recur))))))

(defn expected-headers
  [value]
  {"x-omni-auth-ory-identity-id"    identity-id
   "x-omni-auth-session-active"     (if (= value "inactive-session") "false" "true")
   "x-omni-auth-session-expires-at" expires-at
   "x-omni-auth-identity-active"    (if (= value "inactive-identity") "false" "true")
   "x-omni-auth-email-verified"     (if (= value "unverified") "false" "true")})

(defn assert-scenario!
  [requests value forwarded? forged?]
  (let [before (count @requests)
        status (request value forged?)
        after  (count @requests)]
    (if forwarded?
      (let [headers (last @requests)]
        (when-not (and (= 200 status) (= (inc before) after))
          (throw (ex-info "Expected one forwarded request."
                          {:last-ory-observation (last @ory-observations*)
                           :last-proxy-error     @last-proxy-error*
                           :scenario             value
                           :status               status
                           :upstream-delta       (- after before)})))
        (when-not (= (expected-headers value)
                     (select-keys headers (keys (expected-headers value))))
          (throw (ex-info "Oathkeeper forwarded wrong identity headers."
                          {:actual headers :scenario value})))
        (when (some (complement str/blank?)
                    [(get headers "cookie") (get headers "authorization")])
          (throw (ex-info "Oathkeeper forwarded nonblank credentials."
                          {:scenario value}))))
      (when-not (= before after)
        (throw (ex-info "Rejected request reached upstream." {:scenario value}))))
    (println (str value ": status=" status " upstream-delta=" (- after before)))))

(defn assert-timeout!
  [requests]
  (let [before (count @requests)
        status (request "timeout" false)]
    (Thread/sleep 3500)
    (let [after (count @requests)]
      (when-not (= before after)
        (throw (ex-info "Timed out Ory request reached upstream."
                        {:status status :upstream-delta (- after before)})))
      (println (str "timeout: status=" status " upstream-delta=" (- after before))))))

(defn run
  []
  (reset! ory-observations* [])
  (let [requests (atom [])
        ory      (start-server ory-port (ory-handler ory-observations*))
        upstream (start-server upstream-port (upstream-handler requests))]
    (println "Ory fixture ready.")
    (println "Upstream fixture ready.")
    (println "Oathkeeper ready.")
    (try
      (wait-for-proxy!)
      (assert-scenario! requests "valid" true false)
      (assert-query-not-forwarded!)
      (assert-scenario! requests "valid" true true)
      (doseq [value ["missing" "invalid" "revoked" "error"]]
        (assert-scenario! requests value false false))
      (doseq [value ["unverified" "inactive-identity" "inactive-session"]]
        (assert-scenario! requests value true false))
      (assert-timeout! requests)
      ((:stop ory))
      (assert-scenario! requests "stopped-endpoint" false false)
      0
      (finally
        ((:stop ory))
        ((:stop upstream))))))

(defn -main
  [& _]
  (System/exit (run)))
