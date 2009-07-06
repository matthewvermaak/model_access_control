require File.dirname(__FILE__) + '/../test_helper.rb'

class VendorsControllerTest < ActionController::TestCase
  def setup
    Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 'vendors')
    Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 'employees')
  end

  def test_employee_set
    post :index
    
    assert_not_nil @controller.instance_eval { Employee.current }
  end
end
