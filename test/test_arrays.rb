require 'sugestio'
require "test/unit"

class TestArrays < Test::Unit::TestCase	

	def test_array_multivalued

		client = Sugestio.new('sandbox', 'demo')

		item = {:id => 7, "category[]" => ["pop", "rock"], :from => "2010-11-01", :until => "2010-12-01"}
		result = client.add_item(item)	

		assert_equal(2, result['item'][0]['category'].length)
	end
	
end