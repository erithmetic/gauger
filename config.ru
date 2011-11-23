require 'rack/session/cookie'
require 'rack/contrib'
require 'uri'
require 'cgi'

SPACER_GIF = File.read('spacer.gif')

class Gauger
  attr_accessor :request, :response

  def initialize(env)
    self.request = Rack::Request.new env
    self.response = Rack::Response.new([], 301, { 'Location' => url })
  end

  def track
    set_cookie('_gauges_cookie', 1, 1);
    b = 60 * 60
    d = b * 24
    f = d * 31
    c = d * 365
    i = c * 10
    if (!cookies['_gauges_unique_hour'])
      set_cookie('_gauges_unique_hour', 1, b)
    end
    if (!cookies['_gauges_unique_day'])
      set_cookie('_gauges_unique_day', 1, d)
    end
    if (!cookies['_gauges_unique_month'])
      set_cookie('_gauges_unique_month', 1, f)
    end
    if (!cookies['_gauges_unique_year'])
      set_cookie('_gauges_unique_year', 1, c)
    end
    if (!cookies['_gauges_unique'])
      set_cookie('_gauges_unique', 1, i)
    end
  end

  def url
    a = 'http://secure.gaug.es/track.gif'
    a += "?h[site_id]=" + ENV['GAUGES_SITE_ID']
    a += "&h[resource]=" + CGI::escape(resource)
    a += "&h[referrer]="
    a += "&h[title]="
    a += "&h[user_agent]=" + CGI::escape(agent)
    a += "&h[unique]=" + unique.to_s
    a += "&h[unique_hour]=" + uniqueHour.to_s
    a += "&h[unique_day]=" + uniqueDay.to_s
    a += "&h[unique_month]=" + uniqueMonth.to_s
    a += "&h[unique_year]=" + uniqueYear.to_s
    a += "&h[screenx]=1024"
    a += "&h[browserx]=1024"
    a += "&h[browsery]=768"
    a += "&timestamp=" + Time.now.to_i.to_s
    a
  end

  def cookies
    request.cookies
  end

  def location
    if request.referrer
      URI.parse(request.referrer)
    else
      URI.parse('http://example.com')
    end
  end

  def domain
    location.hostname
  end

  def agent
    request.user_agent
  end

  def resource
    location.to_s
  end

  def uniqueHour
    if (!cookies['_gauges_cookie'])
      return 0
    end
    return cookies['_gauges_unique_hour'] ? 0 : 1
  end

  def uniqueDay
    if (!cookies['_gauges_cookie'])
      return 0
    end
    return cookies['_gauges_unique_day'] ? 0 : 1
  end

  def uniqueMonth
    if (!cookies['_gauges_cookie'])
      return 0
    end
    return cookies['_gauges_unique_month'] ? 0 : 1
  end

  def uniqueYear
    if (!cookies['_gauges_cookie'])
      return 0
    end
    return cookies['_gauges_unique_year'] ? 0 : 1
  end

  def unique
    if (!cookies['_gauges_cookie'])
      return 0
    end
    return cookies['_gauges_unique'] ? 0 : 1
  end

  def set_cookie(key, value, expiry)
    options = { :value => value, :path => '/' }
    options[:expires] = (Time.now + expiry * 1000).gmtime if expiry
    response.set_cookie key, options
  end
end

class GaugerApp
  def call(env)
    gauger = Gauger.new env
    gauger.track
    gauger.response.finish
  end
end

use Rack::Session::Cookie
run GaugerApp.new
