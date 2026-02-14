_: {
  den.aspects.darwin-network-services = {
    includes = [ ];

    darwin.networking.knownNetworkServices = [
      "Thunderbolt Bridge"
      "USB 10/100/1000 LAN"
      "Wi-Fi"
      "iPhone USB"
    ];
  };
}
