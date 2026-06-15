module SpreeRedirections
  module Spree
    module StockItemDecorator
      def self.prepended(base)
        base.after_save :remember_product_stock_state_before_commit,
                        if: :saved_change_to_count_on_hand?

        base.after_commit :trigger_product_stock_status_changed,
                          if: :saved_change_to_count_on_hand?

      end

      private

      def remember_product_stock_state_before_commit
        return unless stock_location.active?

        before_count, after_count = saved_change_to_count_on_hand
        stock_item_was_in_stock = before_count.to_i > 0
        stock_item_is_in_stock = after_count.to_i > 0

        @stock_item_stock_status_changed = stock_item_was_in_stock != stock_item_is_in_stock
        @new_state = stock_item_is_in_stock
      end

      def trigger_product_stock_status_changed
        return unless @stock_item_stock_status_changed

        product = variant&.product
        return unless product

        product.handle_product_stocks_change(@new_state)
      end
    end
  end
end

Spree::StockItem.prepend SpreeRedirections::Spree::StockItemDecorator
