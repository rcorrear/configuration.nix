# Cookie-bearing session checks require TLS unless they stay on loopback.
# Share this pattern between option validation and the runtime environment check.
"^(https://[^/?#[:space:]]+|http://(localhost|127[.]0[.]0[.]1|[[]::1[]])(:[0-9]+)?)([/?#][^[:space:]]*)?$"
