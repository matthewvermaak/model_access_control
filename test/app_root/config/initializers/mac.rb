Mac.configure do |config|
  config.principal Employee do
    Employee.current = Employee.first
  end

  config.intercept Vendor, [:update] do
    if Employee.current && Employee.current == Employee.first
      return true
    end
    return false
  end

  config.secured_filter [Vendor] do
    if Employee.current && Employee.current == Employee.first
      { }
    else
      {:conditions => ["1 = 0"]}
    end
  end
end
