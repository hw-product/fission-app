class AccountsController < ApplicationController

  include BasicCrud

  links :default => proc{|account| account.owner?(current_user)}

  footers(
    :show => 'accounts/order_button'
  )

  labels(
    :default => {
      :success => {
        :method => :subscribed?,
        :text => 'Subscribed'
      },
      :warning => {
        :method => :expired?,
        :text => 'Expired'
      }
    }
  )

end
