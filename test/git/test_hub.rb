require "test/unit"
require "git/hub"
require 'tmpdir'

module TestGit; end

class TestGit::TestHub < Test::Unit::TestCase
  def setup
    @gh  = Git::Hub.new
    @url = 'git@github.com:user/repo.git'
    @http_url = 'https://github.com/user/repo'
    set_url
  end

  def test_remote_origin_url
    actual = nil
    util_git_dir do
      actual = @gh.url
    end
    assert_equal @url, actual
  end

  def test_converted_url
    assert_equal @http_url, @gh.http_url

    set_url 'https://github.com/user/repo.git'
    assert_equal @http_url, @gh.http_url

    set_url 'git://github.com/user/repo.git'
    assert_equal @http_url, @gh.http_url
  end

  def test_converted_url_unkown
    set_url 'unknown'
    e = assert_raises Git::Hub::Error do
      @gh.http_url
    end
    assert_equal 'unprocessable repo url: unknown', e.message
  end

  def test_parse
    assert_equal "#{@http_url}/commit/123",         @gh.parse('123')
    assert_equal "#{@http_url}/commit/HEAD%5E",     @gh.parse('HEAD^')
    assert_equal "#{@http_url}/pulls/42",           @gh.parse('#42')
    assert_equal "#{@http_url}/pulls",              @gh.parse('pulls')
    assert_equal "#{@http_url}/compare/123...124",  @gh.parse('123..124')
    assert_equal "#{@http_url}/compare/HEAD...124", @gh.parse('..124')
    assert_equal "#{@http_url}/compare/123...HEAD", @gh.parse('123..')
    assert_equal "#{@http_url}/master/lib/123.rb",  @gh.parse('/lib/123.rb')
    assert_equal "#{@http_url}/master/lib/123.rb",  @gh.parse('lib/123.rb')
    assert_equal @http_url,                         @gh.parse()
  end

  def set_url url = @url
    @gh.instance_variable_set :@url, url
  end

  def util_git_dir
    set_url nil
    Dir.mktmpdir 'git_hub' do |tmpdir|
      Dir.chdir tmpdir do
        %x'git init .; git config remote.origin.url #{@url}'
        yield
      end
    end
  end
end
