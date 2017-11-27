module Spree
	OrderMerger.class_eval do

    def merge!(other_order, user = nil)

      @previous_order = other_order
      @new_order = self.order
      other_order.line_items.each do |other_order_line_item|
        next unless other_order_line_item.currency == order.currency

        current_line_item = find_matching_line_item(other_order_line_item)
        handle_merge(current_line_item, other_order_line_item)
      end

      set_user(user)
      persist_merge
      merge_child_order
      # So that the destroy doesn't take out line items which may have been re-assigned
      other_order.line_items.reload
      other_order.destroy
    end

    private

    	def merge_child_order
    		if @new_order.children_orders.present?
    			new_order_recipient_names = @new_order.children_orders.collect(&:recipient_name)
    		else
    			new_order_recipient_names = []
    		end
    		if @previous_order.children_orders.present?
    			@previous_order.children_orders.each do |previous_child_order|
    				# to check whether new order has order with same recipient name
    				if new_order_recipient_names.include?(previous_child_order.recipient_name)
    					new_child_order = @new_order.children_orders.find_by_recipient_name(previous_child_order.recipient_name)
    					# Add Line Item to already present order with same recipient name
    					previous_child_order.line_items.each do |line_item|
    						@variant = line_item.variant
								@quantity = line_item.quantity
								@options  =  {}
								new_child_order.contents.add(@variant, @quantity, @options)
    					end
    				else
    					# Create Order if no order present with same recipient name
    					new_child_order = Spree::Order.create(parent_id: @new_order.id, recipient_name: previous_child_order.recipient_name, email: "child_order@example.com")
    					# Add Line Item to newly created order with same recipient name
    					previous_child_order.line_items.each do |line_item|
    						@variant = line_item.variant
								@quantity = line_item.quantity
								@options  =  {}
								new_child_order.contents.add(@variant, @quantity, @options)
    					end
    				end
    			end
    		end
    	end

	end
end