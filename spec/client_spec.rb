require File.dirname(__FILE__) + '/../client'

require File.dirname(__FILE__) + '/../test/typhoeus_mocks.rb'
include TyphoeusMocks

describe "LogicalModel User client" do

  subject{User}

  describe "Attributes" do
    subject{User.new}
    %W(id name email password bio).each do |attribute|
      it { should respond_to attribute }
      it { should respond_to "#{attribute}="}
    end
    describe "attribute definer" do
      it "should add attribute" do
        User.new.attributes.should_not include :this_is_a_new_attribute
        User.new.attributes.should_not include :another_new_attribute
        class User < LogicalModel
          attribute :this_is_a_new_attribute
          attribute :another_new_attribute
        end
        User.new.attributes.should include :this_is_a_new_attribute
        User.new.attributes.should include :another_new_attribute
      end
    end
  end

  describe "RESTActions" do
    %W(find async_find paginate async_paginate delete delete_multiple).each do |class_action|
      it { should respond_to class_action }
    end
  end

  describe "has_many_keys" do
    it { should respond_to 'has_many_keys=' }
    it { should respond_to 'has_many_keys'}
  end

  describe "url_helper" do
    it { should respond_to 'use_ssl=' }
    it { should respond_to 'use_ssl?' }
    it { should respond_to 'url_protocol_prefix' }
    it { should respond_to 'ssl_recommended?' }
    describe "force_ssl" do
      it { should respond_to 'force_ssl' }
      it "sets use_ssl to true" do
        User.use_ssl?.should be_false
        class User; force_ssl; end;
        User.use_ssl?.should be_true
      end
    end
    describe "set_resource_host" do
      it { should respond_to 'set_resource_host' }
      it "sets resource_path" do
        User.resource_path.should == "/api/v1/users"
        class User; set_resource_path("new_path"); end;
        User.resource_path.should == "new_path"
      end
    end
    describe "set_resource_path" do
      it { should respond_to 'set_resource_path'}
      it "sets resource_host" do
        User.host.should == "localhost:3000"
        class User; set_resource_host("new_host"); end;
        User.host.should == "new_host"
      end
    end
  end

  describe "safe_log" do
    it { should respond_to 'log_ok' }
    it { should respond_to 'log_failed' }
    it { should respond_to 'logger' }
    it { should respond_to 'mask_api_key' }
    describe ".log_path" do
      it { should respond_to 'log_path' }
      its(:log_path){ should == "logs/development.log"}
    end
  end

  describe "api_key" do
    describe "set_api_key" do
      it { should respond_to 'set_api_key'}
      it "sets api_key" do
        class User < LogicalModel
          set_api_key(:key_name, 'secret_api_key')
        end
        User.use_api_key.should be_true
        User.api_key.should == 'secret_api_key'
        User.api_key_name.should == :key_name
      end
    end
    describe "use_api_key" do
      it { should respond_to 'use_api_key' }
      context "when true" do
        before(:each) do
          class User < LogicalModel; self.use_api_key=true; self.api_key_name='keyname'; self.api_key="secret_api_key"; end
        end
        it "should send api key in requests" do
          Typhoeus::Request.should_receive(:new).with(User.resource_uri(1),{:params=>{'keyname'=>'secret_api_key'}})
          begin
            User.find(1)
          rescue
          end
        end
        it "should mask api key in logs" do
          response = mock(
              code: 200,
              body: {}.to_json,
              effective_url: "server?keyname=secret_api_key",
              time: 1234
          )
          Logger.any_instance.should_receive(:info).with(/\[SECRET\]/)
          User.log_ok(response)
          Logger.any_instance.should_receive(:warn).with(/\[SECRET\]/)
          User.log_failed(response)
        end
      end
      context "when false" do
        before(:each) do
          class User < LogicalModel; self.use_api_key=false; self.api_key_name='keyname'; self.api_key="secret_api_key"; end
        end
        it "should not send api key in requests" do
          Typhoeus::Request.should_not_receive(:new).with(User.resource_uri(1),{:params=>{'keyname'=>'secret_api_key'}})
          begin
            User.find(1)
          rescue
          end
        end
      end
    end
    it { should respond_to 'merge_key'}
  end

  describe "#create" do
    context "with valid attributes" do
      context "if response is code 201" do
        before(:each) do
          mock_post_with(code: 201, body: {'id' => 3}.to_json)
          @user = User.new({:name => "paul",
                            :email => "paul@pauldix.net", 
                            :password => "strongpass", 
                            :bio => "rubyist"})
          @ret = @user.create
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
        it "should return true" do
          @ret.should be_true
        end
        it "should store code in last_response_code" do
          @user.last_response_code.should == 201
        end
      end
      context "if response is code 202" do
        before(:each) do
          mock_post_with(code: 202, body: {'id' => 3}.to_json)
          @user = User.new({:name => "paul",
                            :email => "paul@pauldix.net", 
                            :password => "strongpass", 
                            :bio => "rubyist"})
          @ret = @user.create
        end
        it "should create a user" do
          @user.should_not be_nil
        end
        it "should store code in last_response_code" do
          @user.last_response_code.should == 202
        end
        it "should set an id" do
          @user.id.should_not be_nil
        end
        it "should hace the same attributes as passed" do
          @user.name.should == "paul"
          @user.email == "paul@pauldix.net"
        end
        it "should return true" do
          @ret.should be_true
        end
      end
    end
  end

  describe "#paginate" do
    context "when successfull" do
      before do
        mock_index(
            collection: [{name:'a',email:'a@m'},
                         {name:'b',email:'b@m'},
                         {name:'c',email:'c@m'}],
            total: 6
        )
        @users = User.paginate(page:1, per_page:1)
      end
      it "should return a Kaminari::PaginatableArray" do
        @users.should be_a(Kaminari::PaginatableArray)
      end
      it "should set total_count" do
        @users.total_count.should == 6
      end
    end
    context "when it fails" do
      before do
        req = Typhoeus::Request.any_instance
        response = mock( code: 500, body: "error", request: "mockedurl", time: 1234 )
        req.stub(:on_complete).and_yield(response)
      end
      it "should retry LogicalModel#retries times (default: 3)" do
        User.retries= 2
        LogicalModel.should_receive(:async_paginate).exactly(2)
        User.paginate(page:1,per_page:1).should be_nil
      end
    end
  end

  describe "#count" do
    before do
      mock_index(
        total: 6
      )
    end
    let(:count){User.count}
    it "should return a Integer" do
      count.should be_a(Integer)
    end
    it "should return total amount of users" do
      count.should == 6
    end
  end

  describe "#find" do
    context "if found" do
      before do
        mock_show(
          attributes: {
            id: 1,
            name: 'mocked-username',
            email: 'mocked@mail',
            password: '1234',
            bio: 'asdfasdf'
          }
        )

        @user = User.find(1)
      end
      it "should set attributes" do
        @user.id.should == 1
        @user.email.should == "mocked@mail"
      end
    end
  end

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

  describe "delete_multiple" do
    before do
      Typhoeus::Request.stub!(:delete).and_return(mock_response(body: 'ok', effective_url: 'mocked-url'))
    end
    context "when disabled" do
      it "should raise exception" do
        class User < LogicalModel; self.enable_delete_multiple = false; end
        expect{User.delete_multiple([1,2,4,5])}.to raise_error
      end
    end
    context "when enabled" do
      it "should raise exception" do
        class User < LogicalModel; self.enable_delete_multiple = true; end
        expect{User.delete_multiple([1,2,4,5])}.not_to raise_error
      end
    end
  end

  describe "#delete_multiple_enabled?" do
    context "with config: 'enable_multiple_delete = true'" do
      before do
        class User < LogicalModel
          self.enable_delete_multiple = true
        end
      end
      it "should return true" do
        User.delete_multiple_enabled?.should be_true
      end
    end
    context "with config: 'enable_delete_multiple = false'" do
        it "should return false" do
        class User < LogicalModel
          self.enable_delete_multiple = false
        end
        User.delete_multiple_enabled?.should be_false
      end
    end
    context "without config" do
      it "should default to false" do
        class AnotherClass < LogicalModel
        end
        AnotherClass.delete_multiple_enabled?.should be_false
      end
    end
  end

  describe "callbacks" do
    describe "before_save" do
      before do
        class User < LogicalModel
          before_save :raise_message

          def raise_message
            raise 'before_save_called'
          end
        end
      end
      it "should be called on #save" do
        u = User.new
        expect{u.save}.to raise_error('before_save_called')
      end
      it "should be called on #create" do
        u = User.new
        expect{u.create}.to raise_error('before_save_called')
      end
      it "should be called on #update" do
        u = User.new
        expect{u.update(id: 1)}.to raise_error('before_save_called')
      end
    end
    describe "before_destroy" do
      before do
        class User < LogicalModel
          before_destroy :raise_message

          def raise_message
            raise 'before_destroy_called'
          end
        end
      end
      it "should not be called on User.delete" do
        expect{User.delete(1)}.not_to raise_error('before_destroy_called')
      end
      it "should be called on #destroy" do
        u = User.new
        expect{u.destroy}.to raise_error('before_destroy_called')
      end
    end
  end

end