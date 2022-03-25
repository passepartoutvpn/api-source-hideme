require "json"
require "resolv"
require "ipaddr"

cwd = File.dirname(__FILE__)
Dir.chdir(cwd)
load "util.rb"

###

template = File.read("../template/servers.json")
ca = File.read("../static/ca.crt")
tls_wrap = read_tls_wrap("crypt", 1, "../static/tc.key", 1)

cfg = {
  ca: ca,
  tlsWrap: tls_wrap,
  cipher: "AES-256-CBC",
  digest: "SHA256",
  compressionFraming: 0,
  renegotiatesAfterSeconds: 900,
  checksEKU: true
}

recommended = {
  id: "default",
  name: "Default",
  comment: "256-bit encryption",
  ovpn: {
    cfg: cfg,
    endpoints: [# FIXME: 3000-3100
      "UDP:3000",
      "UDP:3010",
      "UDP:3020",
      "UDP:3030",
      "UDP:3040",
      "UDP:3050",
      "UDP:3060",
      "UDP:3070",
      "UDP:3080",
      "UDP:3090",
      "UDP:3100",
      "TCP:3000",
      "TCP:3010",
      "TCP:3020",
      "TCP:3030",
      "TCP:3040",
      "TCP:3050",
      "TCP:3060",
      "TCP:3070",
      "TCP:3080",
      "TCP:3090",
      "TCP:3100"
    ]
  }
}

presets = [
  recommended
]

defaults = {
  :username => "username",
  :country => "US"
}

###

entries = []
servers = []

json = JSON.parse(template)
json.each { |server|
  entries << {
    :hostname => server["hostname"],
    :country => server["flag"].upcase,
    :tags => server["tags"]
  }
  next if server["children"].nil?

  server["children"].each { |city|
    entries << {
      :hostname => city["hostname"],
      :country => city["flag"].upcase,
      :area => city["displayName"],
      :tags => server["tags"]
    }
  }
}

entries.each { |entry|
  hostname = entry[:hostname]
  id = hostname.split(".")[0]
  country = entry[:country]

  if ARGV.include? "noresolv"
    addresses = []
  else
    addresses = Resolv.getaddresses(hostname)
  end
  addresses.map! { |a|
    IPAddr.new(a).to_i
  }

  server = {
    :id => id,
    :country => country,
    :hostname => hostname,
    :addrs => addresses
  }
  if entry[:tags].include? "free"
    server[:category] = "free"
  end
  server[:area] = entry[:area] if !entry[:area].nil?
  servers << server
}

###

infra = {
  :servers => servers,
  :presets => presets,
  :defaults => defaults
}

puts infra.to_json
puts
