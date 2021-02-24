//
// Update: 2021-02-23 02:14:14
//

const proxy = "PROXY 192.168.80.201:3128";
// const proxy = "SOCKS5 192.168.80.98:8899";
const direct = "DIRECT;";

const hasOwnProperty = Object.hasOwnProperty;

const zerofinance_domains = {
  "ip138.com": 1,
  "baidu.com": 1
};

const subnet_ips = [
  0, 16777216,              // 0.0.0.0 -> 0.255.255.255
  167772160, 184549376,     // 10.0.0.0/8 -> 10.255.255.255
  1681915904, 1686110208,   // 100.64.0.0/10 -> 100.127.255.255
  2130706432, 2147483648,   // 127.0.0.0/8 -> 127.255.255.255
  -1442971648, -1442906112, // 169.254.0.0/16 -> 169.254.255.255
  -1408237568, -1407188992, // 172.16.0.0/12 -> 172.31.255.255
  -1073741824, -1073741568, // 192.0.0.0/24 -> 192.0.0.255
  -1073741312, -1073741056, // 192.0.2.0/24 -> 192.0.2.255
  -1071660032, -1071659776, // 192.31.196.0/24 -> 192.31.196.255
  -1070284544, -1070284288, // 192.52.193.0/24 -> 192.52.193.255
  -1067949312, -1067949056, // 192.88.99.0/24 -> 192.88.99.255
  -1062731776, -1062666240, // 192.168.0.0/16 -> 192.168.255.255
  -1062260736, -1062260480, // 192.175.48.0/24 -> 192.175.48.255
  -971898880, -971767808,   // 198.18.0.0/15 -> 198.19.255.255
  -969710592, -969710336,   // 198.51.100.0/24 -> 198.51.100.255
  -889163520, -889163264,   // 203.0.113.0/24 -> 203.0.113.255
  -536870912, 0             // 224.0.0.0/3 -> 255.255.255.255
];

function is_ipv4(host) {
  const regex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(:([0-9]|[1-9]\d|[1-9]\d{2}|[1-9]\d{3}|[1-5]\d{4}|6[0-4]\d{3}|65[0-4]\d{2}|655[0-2]\d|6553[0-5]))?$/g;
  if (regex.test(host)) {
    return true;
  }
}

function convert_address(ipchars) {
  if (ipchars.indexOf(':') !== -1) {
    ipchars = ipchars.split(':')[0];
  }
  const bytes = ipchars.split('.');
  const result = ((bytes[0] & 0xff) << 24) |
    ((bytes[1] & 0xff) << 16) |
    ((bytes[2] & 0xff) << 8) |
    (bytes[3] & 0xff);
  return result;
}

// function is_china_domain(domain) {
//   return !!dnsDomainIs(domain, ".cn");
// }

function match_domains(domain, domains) {
  let suffix;
  let pos = domain.lastIndexOf('.');
  pos = domain.lastIndexOf('.', pos - 1);
  while (1) {
    if (pos <= 0) {
      return hasOwnProperty.call(domains, domain);
    }
    suffix = domain.substring(pos + 1);
    if (hasOwnProperty.call(domains, suffix)) {
      return true;
    }
    pos = domain.lastIndexOf('.', pos - 1);
  }
}

function match_subnet_ips(ip, ips) {
  for (let i = 0; i < 28; i += 2) {
    if (ips[i] <= ip && ip < ips[i + 1]) {
      return true;
    }
  }
}

/**
 * @return {string} Connect via direct or proxy.
 */
function FindProxyForURL(url, host) {
  if (typeof host === 'undefined'
    || isPlainHostName(host) === true
    || host === '127.0.0.1'
    || host === 'localhost') {
    return direct;
  }

//   if (is_china_domain(host) === true) {
//     return direct;
//   }

  if (match_domains(host, zerofinance_domains) === true) {
    return proxy;
  }

//   if (is_ipv4(host) === true) {
//     const ip = convert_address(host);
//     if (match_subnet_ips(ip, subnet_ips) === true) {
//       return proxy;
//     }
//   }

  return direct;
}