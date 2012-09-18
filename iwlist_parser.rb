#!/usr/bin/ruby
require 'rubygems'
require 'text-table'

wlan="wlan0" 
nets_data = Array.new
wnets = Array.new
title = ["Name", "Quality", "Channel", "Mac address"]

class WifiNet
    attr_accessor :name
    attr_accessor :quality
    attr_accessor :channel
    attr_accessor :mac
    def initialize(name, quality, ch, mac)
        @name=name
        @quality=quality
        @channel=ch
        @mac=mac
    end
end

# getting the data
def line_value(line)
    if line[/Cell/]
        # strip to take out the white spaces
        return line.split("Address:",2)[-1].strip
    end
    if line[/Frequency/]
        # I only want the channel
        l = line.split("(",2)[-1].strip
        # remove last parentheses. just in case the regexp remove both
        return l.gsub(/[(,),Channel]/, "")
    end
    if line[/ESSID/]
        l = line.split("ESSID:",2)[-1].strip
        return l.gsub(/["]/, "")
    end
    if line[/Quality/]
        l = line.split("Quality=",2)[-1].strip
        # remove everything before first space. (can also use gsub)
        return l[/(\S+)/, 1]
    else
        return ""
    end
end

def quality_to_percent(q)
    n = q.split("/").map(&:to_i)
    return (n[0] * 100) / n[1]
end

`sudo iwlist #{wlan} scan > /tmp/iwlist.tmp`
File.open("/tmp/iwlist.tmp").each do |line|
    if line_value(line)!=""
        nets_data << line_value(line)
    end
end
File.delete("/tmp/iwlist.tmp")

# making objects from the lines info
nets_data.each_slice(4) do |mac,ch,q,name|
    wn = WifiNet.new(name,quality_to_percent(q),ch,mac)
    wnets << wn 
end

# sorting the objects by the signal strength
wnets.sort! do |a, b|
    # reverse sort 
    -(a.quality <=> b.quality)
end

# again we need an array to format the table
# a little bit dirty. can be improved
aux = Array.new
wnets.each do |obj|
    aux << obj.name
    aux << obj.quality
    aux << obj.channel
    aux << obj.mac
end

aux2 = Array.new
aux2 << title
aux.each_slice(4) do |name,quality,channel,mac|
    wn = [name,"#{quality}%",channel,mac]
    aux2 << wn
end
puts aux2.to_table(:first_row_is_head => true)
