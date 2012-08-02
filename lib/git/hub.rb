require 'uri'
module Git; end

class Git::Hub
  VERSION = '1.0.0'
  GIT_REGEX = %r'(?:.+)(?:://|@)(.+)(?::|/)(.+)/(.+)(?:.git)'

  class Error < RuntimeError; end

  def self.parse input
    new.parse input
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
      # we want to display local head, not remote head.
      first = rev_parse('HEAD') if first.empty?
      last  = rev_parse('HEAD') if last.empty?
      range = [first, last].join '...'
      http_url_for 'compare', range
    when /\//
      http_url_for 'master', input
    when /^(?:#|pulls)(\d+)?/
      http_url_for 'pulls', $1
    when nil
      http_url_for
    else
      http_url_for 'commit', rev_parse(input)
    end
  end

  def url
    return @url if @url
    @url = `git config remote.origin.url`.chomp!
  end

  private

  def rev_parse arg
    `git rev-parse --quiet --verify #{arg}`.chomp!
  end

  def http_url_for *args
    # escape is deprecated, but what do I replace it with?
    args.map!{|part| URI.escape part if part}
    [http_url, *args].compact.join '/'
  end
end
