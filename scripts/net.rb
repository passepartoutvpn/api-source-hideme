require "json"
require "resolv"
require "ipaddr"

cwd = File.dirname(__FILE__)
Dir.chdir(cwd)
load "util.rb"

###

servers = File.read("../template/servers.json")
ca = File.read("../static/ca.crt")
tls_wrap = read_tls_wrap("crypt", 1, "../static/tc.key", 1)

cfg = {
    ca: ca,
    wrap: tls_wrap,
    cipher: "AES-256-CBC",
    auth: "SHA256",
    frame: 0,
    reneg: 900,
    eku: true
}

external = {
    hostname: "${id}.hideservers.net"
}

# FIXME: 3000-3100
recommended_cfg = cfg.dup
recommended_cfg["ep"] = [
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
recommended = {
    id: "default",
    name: "Default",
    comment: "256-bit encryption",
    cfg: recommended_cfg,
    external: external
}

presets = [
    recommended
]

defaults = {
    :username => "username",
    :pool => "us",
    :preset => "default"
}

###

entries = []
pools = []

json = JSON.parse(servers)
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

    pool = {
        :id => id,
        :country => country,
        :hostname => hostname,
        :addrs => addresses
    }
    if entry[:tags].include? "free"
        pool[:category] = "free"
    end
    pool[:area] = entry[:area] if !entry[:area].nil?
    pools << pool
}

###

infra = {
    :pools => pools,
    :presets => presets,
    :defaults => defaults
}

puts infra.to_json
puts
