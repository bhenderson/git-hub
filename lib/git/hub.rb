module Git; end

class Git::Hub
  VERSION = '1.0.0'
  GIT_REGEX = %r'(?:.+)(?:://|@)(.+)(?::|/)(.+)/(.+)(?:.git)'

  class Error < RuntimeError; end

  def self.parse input
    new.parse input
  end

  def initialize dir = Dir.pwd
    @dir = dir
  end

  # convert: git@github.com:user/repo.git
  # to: https://github.com/user/repo
  def http_url
    return @http_url if @http_url
    raise Error, "unprocessable repo url: #{url}" unless url =~ GIT_REGEX
    @http_url = "https://#{$1}/#{$2}/#{$3}"
  end

  def parse input = nil
    case input
    when /(\.{2,3})/
      first, last = input.split($1, 2)
      first = 'HEAD' if first.empty?
      last  = 'HEAD' if last.empty?
      range = [first, last].join '...'
      http_url_for 'compare', range
    when /\//
      http_url_for 'master', input
    when /^(?:#|pulls)(\d+)?/
      http_url_for 'pulls', $1
    when nil
      http_url_for
    else
      http_url_for 'commit', input
    end
  end

  def url
    return @url if @url
    Dir.chdir @dir do
      @url = `git config remote.origin.url`.chomp!
    end
  end

  private

  def head
    `git rev-parse HEAD`.chomp! || 'HEAD'
  end

  def http_url_for *args
    [http_url, *args].compact.join '/'
  end
end
