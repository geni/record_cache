module RecordCache
  # In Rails 2.3, update_all and delete_all were class methods that took conditions, so
  # RecordCache::ClassMethods was able to intercept every bulk update.  In Rails 8 the
  # conditions live on a relation (Model.where(...).update_all(...)) and the relation never
  # touches the class methods, so bulk updates would silently leave the record cache stale.
  module RelationMethods
    def update_all(updates)
      invalidating_record_cache(:update) { super }
    end

    def delete_all
      invalidating_record_cache { super }
    end

    private

    def invalidating_record_cache(flag = nil)
      return yield unless klass.respond_to?(:invalidate_from_conditions)

      # Without conditions every row is affected, so bumping the version is cheaper than
      # collecting (potentially all) ids.  This matches the class method behavior.
      if where_clause.empty? and limit_value.nil?
        result = yield
        klass.increment_version
        return result
      end

      ids = pluck(primary_key)
      return yield if ids.empty?

      # Note that invalidate_from_conditions invalidates both before and after the update, so
      # the rows are removed from the cached indexes of their old *and* new field values.
      klass.invalidate_from_conditions({primary_key => ids}, flag) { yield }
    end
  end
end

ActiveRecord::Relation.prepend(RecordCache::RelationMethods)
