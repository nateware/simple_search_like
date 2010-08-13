require File.expand_path 'spec_helper', File.dirname(__FILE__)

class User < ActiveRecord::Base
end

describe "SimpleSearch" do
  it "should add search methods to ActiveRecord::Base" do
    User.respond_to?(:simple_search).should.be.true
    User.respond_to?(:simple_search_like).should.be.true
    User.respond_to?(:simple_search_conditions).should.be.true
  end
end
