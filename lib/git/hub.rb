require 'cgi'
module Git; end

class Git::Hub
  VERSION = '1.0.2'
  GIT_REGEX = %r'\A(?:.+)(?:://|@)(.+)(?::|/)(.+)/(.+)(?:.git)\z'

  class Error < RuntimeError; end

  def self.parse *args
    new.parse(*args)
  end

  def initialize
    @http_url = nil
  end

  # convert: git@github.com:user/repo.git
  # to:  https://github.com/user/repo
  def http_url
    return @http_url if @http_url
    raise Error, "unprocessable repo url: #{url}" unless url =~ GIT_REGEX
    @http_url = "http://#{$1}/#{$2}/#{$3}"
  end

  def parse input = nil
    case input
    when /(\.{2,3})/
      first, last = input.split($1, 2)
      first = 'HEAD' if first.empty?
      last  = 'HEAD' if last.empty?
      range = [first, last].join '...'

      cmd  = 'compare'
      rest = range
    when /\//
      cmd  = 'tree/master'
      rest = input.sub(/\A\/?/, '')
    when /^(?:#|pulls)(\d+)?/
      cmd  = 'pulls'
      rest = $1
    when nil
    else
      cmd  = 'commit'
      rest = input
    end

    http_url_for cmd, *rest
  end

  def url
    @url ||= `git config remote.origin.url`.chomp!
  end

  private

  def http_url_for *args
    args = args.compact.join('/').split('/').map!{|p| CGI.escape p}
    [http_url, *args].join '/'
  end
end
