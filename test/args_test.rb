require_relative './test_helper'

describe 'args' do
  describe "version" do
    before do
      @version_format = /v\d\.\d\.\d/
    end

    it "-v" do
      shell("deliver -v").must_match @version_format
    end

    it "--version" do
      shell("deliver --version").must_match @version_format
    end
  end

  describe "strategies" do
    it "-s" do
      output = shell("deliver -s")
      output.must_match "ruby"
      output.must_match "gh-pages"
      output.must_match "nodejs"
    end

    it "--strategies" do
      output = shell("deliver --strategies")
      output.must_match "ruby"
      output.must_match "gh-pages"
      output.must_match "nodejs"
    end
  end

  describe "specifying a strategy via args" do
    it "returns an error if strategy does not exist" do
      shell("deliver foobar").must_match /strategy does not exist/
    end
  end
end
