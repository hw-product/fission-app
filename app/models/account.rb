class Account < ModelBase

  bucket :accounts

  value :name

  index :name, :unique => true
  link :owner, User
  links :members, User
  links :jobs, Job

  class << self
    def display_attributes
      [:name, :owner]
    end

    def restrict(user)
      ([user.base_account] + user.accounts).compact.uniq
    end
  end

  def to_s
    name
  end

end
