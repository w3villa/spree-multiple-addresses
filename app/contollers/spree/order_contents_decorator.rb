module Spree
	OrderContents.class_eval do 

		def update_cart(params)
      if order.update_attributes(filter_order_items(params))
        order.line_items = order.line_items.select { |li| li.quantity > 0 }
        # Update totals, then check if the order is eligible for any cart promotions.
        # If we do not update first, then the item total will be wrong and ItemTotal
        # promotion rules would not be triggered.
        persist_totals
        PromotionHandler::Cart.new(order).activate
        order.ensure_updated_shipments
        persist_totals
        true
      else
        false
      end
    end

	end
end