require './lib/typhoeus_fix/array_decoder.rb'

describe TyphoeusFix do
  include TyphoeusFix

  describe "decode" do
    describe "for an encoded array" do
      let!(:ar){ {ids: {'0' => :v0,
                        '1' => :v1,
                        '2' => :v2,
                        '3' => :v3,
                        '4' => :v4,
                        '5' => :v5,
                        '6' => :v6,
                        '7' => :v7,
                        '8' => :v8,
                        '9' => :v9,
                        '10' => :v10,
      }} }
      it "respects items order" do
        decode!(ar)
        ar[:ids].should == [:v0, :v1, :v2, :v3, :v4, :v5, :v6, :v7, :v8, :v9, :v10]
      end
    end
  end
end
