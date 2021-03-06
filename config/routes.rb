Rails.application.routes.draw do

  namespace :api do

    resources :products, only: [:index, :show]

    resource :user, only: [:create, :update]
    match 'profile/balance' => "users#update", via: :patch

    resource :session, only: [:create, :destroy]

    resources :purchases, only: [:index, :show, :create, :destroy]
    match '/purchases/drop' => 'purchases#destroy', via: :post

    resources :orders, only: [:index, :show, :create, :update]
    match '/orders/:id/payment' => 'orders#update', via: :post

    resources :gift_certificates
    match '/gift_certificates/generate' => 'gift_certificates#generate', via: :post
  end

end
