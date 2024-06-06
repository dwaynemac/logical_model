require './lib/logical_model'

describe "LogicalMode::SafeLog" do
  before do
    Rails.logger = Logger.new(STDOUT)
  end
  describe "InstanceMethods" do
  end
  describe "ClassMethods" do
    let(:response) {
      double("response", :code => 200, :effective_url => "http://example.com", :time => 0.5, :body => "body")
    }

    describe "safe_body" do
      class Example < LogicalModel
        sensitive_attribute :secret
        attribute :public
      end
      describe "if body is a json string" do
        let(:body) { {secret: "1234", public: {saludo: "hola", to: "vos", array: [1, 2, 3, 4, 5]}}.to_json }
        it "masks sensitive attributes wout altering other values" do
          Example.safe_body(body).should eq({
              secret: LogicalModel::SafeLog::SECRET_PLACEHOLDER,
              public: {saludo: "hola", to: "vos", array: [1, 2, 3, 4, 5]}
            }.to_json
          )
        end
      end
      describe "if body is a non-json string" do
        let(:body) { "acahaydata" }
        it "returns body" do
          Example.safe_body(body).should eq(body)
        end
      end
    end

  end

end
