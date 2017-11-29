module Spree
  module Admin
  	PaymentsController.class_eval do

  		def fire
			  return unless event = params[:e] and @payment.payment_source
			  # Because we have a transition method also called void, we do this to avoid conflicts.
			  event = "void_transaction" if event == "void"
			  if @payment.send("#{event}!")
			  	unless @order.children_orders.blank?
				  	@order.children_orders.each do |child_order|  
				  		child_order.payments.last.send("#{event}!")
				  	end
				  end
			    flash[:success] = Spree.t(:payment_updated)
			  else
			    flash[:error] = Spree.t(:cannot_perform_operation)
			  end
			rescue Spree::Core::GatewayError => ge
			  flash[:error] = "#{ge.message}"
			ensure
			  redirect_to admin_order_payments_path(@order)
			end

  	end
  end
end