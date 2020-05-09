require "json"
require "resolv"
require "ipaddr"

cwd = File.dirname(__FILE__)
Dir.chdir(cwd)

###

def read_tls_wrap(strategy, dir, file, from, to)
    lines = File.foreach(file)
    key = ""
    lines.with_index { |line, n|
        next if n < from or n >= to
        key << line.strip
    }
    key64 = [[key].pack("H*")].pack("m0")

    return {
        strategy: strategy,
        key: {
            dir: 1,
            data: key64
        }
    }
end

###

servers = File.read("../template/servers.json")
ca = File.read("../static/ca.crt")
tls_wrap = read_tls_wrap("crypt", 1, "../static/tc.key", 1, 17)

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
    "TCP:3000"
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
