require File.dirname(__FILE__) + '/../test_helper.rb'

class MacTest < Test::Unit::TestCase 
 
  def setup
    Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 'vendors')
    Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 'employees')
    Employee.current = nil
  end
  
  def test_that_a_vendor_can_not_be_saved_with_no_user
    v = Vendor.first
    assert_equal false, v.save
  end

  def test_that_a_vendor_can_be_saved_with_the_right_user
    v = Vendor.first
    Employee.current = Employee.first

    assert_equal true, v.save
  end

  def test_that_a_secured_find_returns_nothing_for_anon
    vendors = Vendor.secured.all
    
    assert_equal [], vendors    
  end

  def test_that_a_super_user_finds_all
    Employee.current = Employee.first
    vendors = Vendor.secured.all
  
    assert_equal Vendor.all.size, vendors.size 
  end
end
