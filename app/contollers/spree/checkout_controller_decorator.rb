module Spree
	CheckoutController.class_eval do 

		before_filter :update_child_orders, only: [:update]


		def update
      if @order.update_from_params(params, permitted_checkout_attributes, request.headers.env)
        @order.temporary_address = !params[:save_user_address]
        unless @order.next
          flash[:error] = @order.errors.full_messages.join("\n")
          redirect_to(checkout_state_path(@order.state)) && return
        end

        if @order.completed?
          @current_order = nil
          flash.notice = Spree.t(:order_processed_successfully)
          flash['order_completed'] = true
          redirect_to completion_route
        else
          redirect_to checkout_state_path(@order.state)
        end
      else
        render :edit
      end
    end

		private

			def update_child_orders
        begin
          ActiveRecord::Base.transaction do  
            if params[:state] == "address"
              @order.children_orders.each_with_index do |child_order, index|
                @bill_address = Spree::Address.create((params[:order][:bill_address_attributes]).permit(:firstname, :lastname, :address1, :address2, :city, :zipcode, :state_id, :country_id, :phone))

                if @bill_address.errors.present?
                  raise Exception.new(@bill_address.errors.full_messages.join(','))
                end
                # handling the case if user comes back from address later state to address state again
                if child_order.bill_address.present?
                  child_order.bill_address.destroy
                end

                if child_order.ship_address.present?
                  child_order.ship_address.destroy
                end

                if index == 0
                  @ship_address = get_ship_address()
                else
                  @ship_address = Spree::Address.create((params[:child_orders][(index).to_s][:ship_address_attributes]).permit(:firstname, :lastname, :address1, :address2, :city, :zipcode, :state_id, :country_id, :phone))
                end
                p "111111"*20
                p @bill_address
                p @ship_address
                if @ship_address.errors.present?
                  raise Exception.new(@ship_address.errors.full_messages.join(','))
                end
                p @ship_address.errors
                child_order.update_attributes(bill_address_id: @bill_address.id)
                child_order.update_attributes(ship_address_id: @ship_address.id)
                if child_order.state == "address"
                  child_order.next
                end
              end
            elsif params[:state] == "delivery"
              @order.children_orders.each_with_index do |child_order, counter|
                child_order.shipments.last.shipping_rates.update_all(selected: false)
                Spree::ShippingRate.find((params[:child_orders][counter.to_s][:selected_shipping_rate_id]).to_i).update_attributes(selected: true)
                if child_order.state != "delivery"
                  child_order.update_attributes(state: "delivery")
                end
                child_order.next
              end
              total_shipment = @order.children_shipment_sum
              shipping_rate = @order.shipments.last.selected_shipping_rate
              shipping_rate.update_attributes(cost: total_shipment)
              @order.set_shipments_cost
              @order.update_totals
              @order.persist_totals
            elsif params[:state] == "payment"
              payment_method = Spree::PaymentMethod.where(name: "check").last
              @order.children_orders.each do |child_order|
                child_order.payments.create(amount: child_order.total, payment_method_id: payment_method.id)
                child_order.next
              end
              if @order.user.present?
                @order.children_orders.update_all(user_id: @order.user_id)
              end
            end
          end
        rescue Exception => error
          p "6666"*20
          p "Exception "*20
          p error.message
          # p error.backtrace.join("\n")
          redirect_to :back, :flash=> {:error => error.message}
          return
        end
			end

      def get_ship_address
        if @order.user.present?
          if params[:order][:use_billing].present?
            if params[:order][:ship_address_attributes].present?
              if params[:order][:ship_address_attributes][:id].present?
                # if user address exist and opted for use billing option
                user_ship_address = Spree::Address.find(params[:order][:ship_address_attributes][:id].to_i)
                @ship_address = Spree::Address.create(firstname: user_ship_address.firstname,lastname: user_ship_address.lastname,address1: user_ship_address.address1,address2:  user_ship_address.address2,city: user_ship_address.city,zipcode: user_ship_address.zipcode, phone: user_ship_address.phone,state_id: user_ship_address.state_id, country_id: user_ship_address.country_id, phone: user_ship_address.phone)
                # @ship_address = user_ship_address.clone.save
              else
                # if user address does not exist and opted for not using billing option
                @ship_address = Spree::Address.create((params[:order][:ship_address_attributes]).permit(:firstname, :lastname, :address1, :address2, :city, :zipcode, :state_id, :country_id, :phone))
              end
            else
              # if user address does not exist and opted for use billing option
              @ship_address = Spree::Address.create((params[:order][:bill_address_attributes]).permit(:firstname, :lastname, :address1, :address2, :city, :zipcode, :state_id, :country_id, :phone))
            end
          else
            @ship_address = Spree::Address.create((params[:order][:ship_address_attributes]).permit(:firstname, :lastname, :address1, :address2, :city, :zipcode, :state_id, :country_id, :phone))
          end
        else
          # For Guest Checkout
          if params[:order][:use_billing].present?
            @ship_address = Spree::Address.create((params[:order][:bill_address_attributes]).permit(:firstname, :lastname, :address1, :address2, :city, :zipcode, :state_id, :country_id, :phone))
          else
            @ship_address = Spree::Address.create((params[:order][:ship_address_attributes]).permit(:firstname, :lastname, :address1, :address2, :city, :zipcode, :state_id, :country_id, :phone))
          end
        end
      end
	end
end