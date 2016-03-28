Ziply::Application.routes.draw do

  mount RedactorRails::Engine => '/redactor_rails'
  mount Ckeditor::Engine => '/ckeditor'
  resources :customer_services do
    collection do
      post :sign_in
      post :forgot_password
      post :change_password
      post :update_customer
      get :remove_pic
      post :new_package
      post :save_package
      post :create_order
      post :get_package_size_amount
      post :save_payment_method
      post :get_payment_methods
      post :get_jobs
      post :update_payment_method
      post :get_messages
      post :update_profile
      post :send_message
      post :forgot_password
      post :delete_payment_method
      post :delete_message
      post :view_profile
      post :save_review
      post :search_jobs
      post :search_messages
      post :search_messages
      post :cancel_order
      post :change_password
      post :track_driver
      post :accepted_job_count
      post :change_read_status
      post :update_customer_setting
      post :check_promo_code
    end
  end


  resources :services do
    collection do
      post :get_jobs
      post :sign_in
      post :get_driver_setting
      post :get_driver_detail
      post :get_messages
      post :delete_message
      post :accept_job
      post :get_billing_histories
      post :get_billing_history
      post :get_reviews
      post :get_review
      post :get_profile
      post :clock_in
      post :clock_out
      post :get_histories
      post :upload_signature
      post :search_jobs
      post :change_job_status
      post :sign_in_for_delivery
      post :save_message
      post :upload_driver_picture
      post :update_driver_profile
      post :change_password
      post :get_messages
      post :change_message_status
      post :update_driver_setting
      post :clock_in_clock_out
      post :forgot_password
      post :get_driver_stats
      post :get_driver_delivery_stats
      post :sign_out
      post :get_driver_data
      post :update_driver_distance
      post :get_job
      post :get_message
      get :push_testing
      post :support_request
      post :cancel_order
      post :get_jobs_history
    end
  end

  #resources :services do
  #  collection do
  #    get :get_jobs
  #    get :sign_in
  #    get :get_driver_setting
  #    get :get_driver_detail
  #    get :get_job
  #    get :get_messages
  #    get :get_message
  #    get :delete_message
  #    get :accept_job
  #    get :get_billing_histories
  #    get :get_billing_history
  #    get :get_reviews
  #    get :get_review
  #    get :get_profile
  #    get :clock_in
  #    get :clock_out
  #    get :get_histories
  #  end
  #end
  #

  #devise_for :users
  root :to => "home#index"
  get "/super_admins" => "super_admin/home#index"
  get "/customers" => "customer/home#index"
  get "/drivers" => "driver/home#index"
  #match "/partners" => "partner/home#index"

  get "/our-drivers" => "our_drivers#index"
  get "/about-us" => "home#about_us"
  get "/locations" => "home#locations"
  get "/contact-us" => "home#contact_us"
  get "/press" => "home#press"
  get "/support" => "home#support"
  get "/shipping-policy" => "home#shipping_policy"
  get "/terms" => "home#terms"
  get "/privacy" => "home#privacy"
  get "/become-driver" => "home#become_driver"
  get "/confirmed-driver" => "home#confirmed_driver"
  get "/blogs" => "home#blogs"
  match ':id/invitations' => "home#become_driver", :via => [:get]

  resources :our_drivers do

  end

  get "/track-package" => "home#track_package"

  resources :home do
    collection do
      get :become_driver
      post :new_driver
      get :driver_success
      get :driver_success_account
      get :track_package
      get :search_package
      get :track_package_result
      get :new_index
      post :ziply_update
      post :contact_us_message
      post :create_confirm_driver
    end
  end

  namespace :super_admin do

    resources :coupon_codes do
      collection do
        get :get_users
        get :search_coupon
      end
    end

    resources :jobs do
      collection do
       get :cancel_order
       get :cancel_driver
      end
    end
    resources :blogs do
      collection do
       get :disable_blog
      end
    end
    resources :file_claims do
      collection do
     get :claim_file
      end
    end
    resources :dashboard
    resources :profiles do
      collection do
        get :profile
        post :update
        put :update
      end
    end
    resources :packages
    resources :phone_types
    resources :vehicle_types
    resources :payment_methods do
      collection do
        get :del_pop_up
        get :delete_payment_method
      end
    end
    resources :drivers do
      collection do
        get :invite
        get :confirm_pop_up
        get :new_bank_account
        post :create_bank_account
        get :edit_bank_account
        get :disable_driver
        post :update_bank_account
        get :track_driver
        get :get_lat_long
      end
    end
    resources :customers do
      collection do
        get :search_customer
        get :disable_customer
      end
    end
  end

  namespace :customer do
    resources :home
    resources :file_claims do
      collection do
        get :delete_claim
        get :del_pop_up
      end
    end
    resources :reviews
    resources :payment_methods do
      collection do
        get :del_pop_up
        get :delete_payment_method
      end
    end
    resources :locations do
      collection do
        get :del_pop_up
        get :delete_location
      end
    end
    resources :transactions
    resources :dashboard
    resources :customers do
      collection do
        get :profile
        post :upload_photo
        post :update
        put :update
      end
    end
    resources :messages do
      collection do
        get :reply
        get :get_message
        get :del_pop_up
        get :delete_message
        get :message_sent
        get :search_messages
      end
    end
    resources :jobs do
      collection do
        get :get_location
        get :order
        post :create_order
        get :get_payment_method
        get :get_billing_address
        get :success
        get :get_package
        get :sign_in_pop_up
        get :sign_up_pop_up
        get :search_jobs
        get :print_receipt_pdf
        get :set_cookies
        get :search_jobs_by_date
        get :get_jobs
        get :cancel_order_pop_up
        get :cancel_order
        get :get_package_sizes
        get :check_promo_code
      end
    end
  end

  namespace :driver do
    resources :home
    resources :dashboard
    resources :reportings do
      collection do
        get :get_driver_stats
        get :get_driver_delivery_stats
      end
    end
    resources :bank_accounts do
      collection do
        get :edit_account
        post :update_account
      end
    end
    resources :reviews
    resources :drivers do
      collection do
        get :profile
        post :upload_photo
      end
    end

    resources :messages do
      collection do
        get :reply
        get :get_message
        get :del_pop_up
        get :delete_message
        get :message_sent
      end
    end
    resources :jobs do
      collection do
        get :get_location
        get :order
        post :create_order
        get :get_payment_method
        get :get_billing_address
        get :success
        get :get_package
        get :sign_in_pop_up
        get :sign_up_pop_up
        get :search_jobs
        get :print_receipt_pdf
        get :set_cookies
        get :search_jobs_by_date
        get :cancel_order
      end
    end
  end


  #namespace :driver do
  #  resources :driver
  #  resources :jobs do
  #    collection do
  #      get :sign_in_pop_up
  #    end
  #  end
  #end


  #namespace :customer do
  #  resources :payment_methods
  #  resources :reviews
  #  resources :locations
  #  #resources :customers do
  #  #  collection do
  #  #    get :profile
  #  #    post :upload_photo
  #  #  end
  #  #end
  #
  #  resources :messages do
  #    collection do
  #      get :reply
  #    end
  #  end
  #
  #  resources :jobs do
  #    collection do
  #      get :get_location
  #      get :order
  #      post :create_order
  #      get :get_payment_method
  #      get :get_billing_address
  #      get :success
  #      get :get_package
  #      get :sign_in_pop_up
  #      get :sign_up_pop_up
  #    end
  #  end
  #
  #  resources :dashboard do
  #    collection do
  #      get :index
  #    end
  #  end
  #
  #end


  devise_for :users, :controllers => {
      :sessions => "users/sessions",
      :confirmation => "users/confirmations",
      :passwords => "users/passwords",
      :registrations => "users/registrations",
      :unlocks => "users/unlocks",
      :omniauth_callbacks => "users/omniauth_callbacks"
  }

  devise_scope :user do
    get "sign_in" => "users/sessions#new"
    get "sign_up" => "users/registrations#new"
    get "sign_out" => "users/sessions#destroy"
    get "change_password" => "users/registrations#change_password"
    post "update_password" => "users/registrations#update_password"
    get "/super_admin" => "users/sessions#super_admin_new"
    put "update_driver" => "users/registrations#update_driver"
    get 'invite_complete' => "users/registrations#invite_complete"
    post "customer_create" => "users/registrations#create"
  end

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  #match ':controller(/:action(/:id(.:format)))'

end
