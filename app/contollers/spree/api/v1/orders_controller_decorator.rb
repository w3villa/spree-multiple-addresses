module Spree
  module Api
    module V1
      OrdersController.class_eval do  

				def index
				  authorize! :index, Order
				  @orders = Order.where.not(parent_id: nil).ransack(params[:q]).result.page(params[:page]).per(params[:per_page])
				  respond_with(@orders)
				end

			end
		end
	end
end