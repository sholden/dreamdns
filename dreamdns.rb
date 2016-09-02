#!/usr/bin/env ruby

require 'json'
require 'logger'
require 'net/http'
require 'uri'

KEY = ENV['DREAMHOST_API_KEY'] || raise('Missing env DREAMHOST_API_KEY')
DNS_RECORD = ENV['DREAMHOST_DNS_RECORD'] || raise('Missing env DREAMHOST_DNS_RECORD')
LOGGER = Logger.new(STDOUT)

def update_loop
  current_dns_ip = get_dns_ip
  LOGGER.info "Initial DNS IP: #{current_dns_ip}"

  while true
    begin
      current_ip = get_ip

      if current_ip != current_dns_ip
        LOGGER.info "Updating DNS: #{current_ip}"
        remove_dns_ip(current_dns_ip)
        add_dns_ip(current_ip)
        current_dns_ip = get_dns_ip
      else
        LOGGER.info "Verified DNS: #{current_ip}"
      end
    rescue StandardError => e
      LOGGER.error e
    end

    sleep(60 * 15)
  end
end

def get_ip
  request(ip_uri)['ip']
end

def get_dns_ip
  response = request(list_uri)

  if response['result'] != 'success'
    puts JSON.pretty_generate(response)
    raise "Dreamhost API failure: #{response['result']}"
  end

  record = response['data'].find{|dns| dns['record'] == DNS_RECORD}
  record && record['value']
end

def add_dns_ip(ip)
  response = request(add_uri(ip))

  if response['result'] != 'success'
    raise "Dreamhost API failure: #{response['result']}"
  end
end

def remove_dns_ip(ip)
  response = request(remove_uri(ip))

  if response['result'] != 'success'
    raise "Dreamhost API failure: #{response['result']}"
  end
end

def request(uri)
  JSON.parse(Net::HTTP.get(uri))
end

def ip_uri
  URI('https://api.ipify.org?format=json')
end

def list_uri
  URI("https://api.dreamhost.com/?key=#{KEY}&cmd=dns-list_records&format=json")
end

def add_uri(ip)
  URI("https://api.dreamhost.com/?key=#{KEY}&cmd=dns-add_record&record=#{DNS_RECORD}&type=A&value=#{ip}&format=json")
end

def remove_uri(ip)
  URI("https://api.dreamhost.com/?key=#{KEY}&cmd=dns-remove_record&record=#{DNS_RECORD}&type=A&value=#{ip}&format=json")
end

update_loop if __FILE__ == $0
