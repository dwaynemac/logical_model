require File.dirname(__FILE__) + '/../client'

# NOTE: to run these specs you must have the service running locally. Do like this:
# ruby service.rb -p 3000 -e test

# Also note that after a single run of the tests the server must be restarted to reset
# the database. We could change this by deleting all users in the test setup.

# TODO testing in these specs should be focus on LogicalModel behaviour.
describe "LogicalModel User client" do
  before(:each) do
    # User.destroy_all
    # User.base_uri = "http://localhost:3000"

    # @user = User.find_by_name(:name => "paul")
    # User.delete(@user.id)
#    User.destroy("trotter")

    # @user = User.new({:name => "bryan", 
    #                         :email => "bryan@spamtown.usa", 
    #                         :password => "strongpass", 
    #                         :bio => "rubyist"})
    # @user.create
    # User.create(
    #   :name => "paul",
    #   :email => "paul@pauldix.net",
    #   :password => "strongpass",
    #   :bio => "rubyist")
    # User.create(
    #   :name => "bryan",
    #   :email => "bryan@spamtown.usa",
    #   :password => "strongpass",
    #   :bio => "rubyist")
  end

  describe "#create" do
    context "with valid attributes" do
      before(:each) do
        @user = User.new({:name => "paul", 
                          :email => "paul@pauldix.net", 
                          :password => "strongpass", 
                          :bio => "rubyist"})
        @user.create
      end
      it "should create a user" do
        @user.should_not be_nil
      end
      it "should set an id" do
        @user.id.should_not be_nil
      end
      it "should hace the same attributes as passed" do
        @user.name.should == "paul"
        @user.email == "paul@pauldix.net"
      end
    end
  end

#  describe "#find" do
#    it "should GET resource by id" do
#      pending "on it to work"
      #user = User.find(@user.id)
      #user["name"].should  == "paul"
      #user["email"].should == "paul@pauldix.net"
      #user["bio"].should   == "rubyist"
#    end
#    it "should return nil for a user not found" do
#      pending "on it to work"
      #User.find_by_name("gosling").should be_nil
#    end    
#  end
  
#  describe "#paginate" do
    
#  end
  
#   describe "#update" do
    
#   end
  
  describe "#https" do
    context "when use_ssl is tue" do
      before(:each) do
        class User < LogicalModel;self.use_ssl = true;end
      end
      it "should use https://" do
        User.resource_uri.should match /https/
      end
    end
    context "when use_ssl is false" do
      before(:each) do
        class User < LogicalModel;self.use_ssl = false;end
      end
      it "should use http://" do
        User.resource_uri.should match /http/
        User.resource_uri.should_not match /https/
      end
    end
  end
  
  

#  it "should create a user" do
#    user = User.create({
#      :name => "trotter",
#      :email => "trotter@spamtown.usa",
#      :password => "whatev"})
#    User.find_by_name("trotter")["email"].should == "trotter@spamtown.usa"
#  end

#  it "should update a user" do
#    user = User.update("paul", :bio => "rubyist and author")
#    user["name"].should == "paul"
#    user["bio"].should  == "rubyist and author"
#    User.find_by_name("paul")["bio"] == "rubyist and author"
#  end

#  it "should destroy a user" do
#    User.destroy("bryan").should == true
#    User.find_by_name("bryan").should be_nil
#  end

#  it "should verify login credentials" do
#    user = User.login("paul", "strongpass")
#    user["name"].should == "paul"
#  end

#  it "should return nil with invalid credentials" do
#    User.login("paul", "wrongpassword").should be_nil
#  end
end