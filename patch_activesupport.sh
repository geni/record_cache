#!/bin/sh
# Patch Rails 3.2.x for Ruby 2.7+ compatibility
# Based on tr8n gem's patch script

# Find the Rails gem directories dynamically
ACTIVESUPPORT_DIR=$(find vendor/bundle/ruby/2.7.0/gems/activesupport-3.* -maxdepth 0 -type d 2>/dev/null | head -1)
ACTIVERECORD_DIR=$(find vendor/bundle/ruby/2.7.0/gems/activerecord-3.* -maxdepth 0 -type d 2>/dev/null | head -1)
AREL_DIR=$(find vendor/bundle/ruby/2.7.0/gems/arel-* -maxdepth 0 -type d 2>/dev/null | head -1)

TIMEZONE_FILE="$ACTIVESUPPORT_DIR/lib/active_support/values/time_zone.rb"
BIGDECIMAL_FILE="$ACTIVESUPPORT_DIR/lib/active_support/core_ext/big_decimal/conversions.rb"
POSTGRESQL_FILE="$ACTIVERECORD_DIR/lib/active_record/connection_adapters/postgresql_adapter.rb"

# Patch 1: Fix TimeZone#parse circular argument reference
if [ -f "$TIMEZONE_FILE" ]; then
  # Check if already patched
  if grep -q "def parse(str, now_time=nil)" "$TIMEZONE_FILE"; then
    echo "TimeZone already patched for Ruby 2.7"
  else
    echo "Patching TimeZone for Ruby 2.7 compatibility..."
    # Use perl for more reliable multi-line substitution
    perl -i -pe 's/def parse\(str, now=now\)/def parse(str, now_time=nil)\n      now_time ||= now/' "$TIMEZONE_FILE"
    perl -i -pe 's/time = Time\.parse\(str, now\) rescue DateTime\.parse\(str\)/time = Time.parse(str, now_time) rescue DateTime.parse(str)/' "$TIMEZONE_FILE"
    echo "TimeZone patch applied successfully"
  fi
fi

# Patch 2: Fix BigDecimal yaml_as -> yaml_tag
if [ -f "$BIGDECIMAL_FILE" ]; then
  if grep -q "yaml_tag" "$BIGDECIMAL_FILE"; then
    echo "BigDecimal already patched for Ruby 2.7"
  else
    echo "Patching BigDecimal for Ruby 2.7 compatibility..."
    sed -i 's/yaml_as/yaml_tag/' "$BIGDECIMAL_FILE"
    echo "BigDecimal patch applied successfully"
  fi
fi

# Patch 2b: Fix BigDecimal.new removed in Ruby 2.7 (Rails 3.2 duplicable.rb)
DUPLICABLE_FILE="$ACTIVESUPPORT_DIR/lib/active_support/core_ext/object/duplicable.rb"
if [ -f "$DUPLICABLE_FILE" ]; then
  if grep -q "BigDecimal\.new" "$DUPLICABLE_FILE"; then
    echo "Patching BigDecimal.new for Ruby 2.7 compatibility..."
    # Replace BigDecimal.new with BigDecimal() for Ruby 2.7+
    sed -i "s/BigDecimal\.new(/BigDecimal(/g" "$DUPLICABLE_FILE"
    echo "BigDecimal.new patch applied successfully"
  fi
fi

# Patch 3: Fix PGconn renamed to PG::Connection in pg gem 1.x AND panic -> error
if [ -f "$POSTGRESQL_FILE" ]; then
  NEEDS_PATCH=0

  # Rails 3.2 specific: Remove the hard-coded pg version requirement
  if grep -q "gem 'pg', '~> 0.11'" "$POSTGRESQL_FILE"; then
    echo "Patching PostgreSQL adapter pg version requirement..."
    sed -i "/gem 'pg', '~> 0.11'/d" "$POSTGRESQL_FILE"
    NEEDS_PATCH=1
  fi

  if grep -q "PGconn\|PGresult\|PGError" "$POSTGRESQL_FILE"; then
    echo "Patching PostgreSQL adapter for pg gem 1.x..."
    # Replace all PGconn, PGresult, and PGError references with PG:: equivalents
    sed -i 's/PGconn\./PG::Connection./g' "$POSTGRESQL_FILE"
    sed -i 's/PGconn::/PG::Connection::/g' "$POSTGRESQL_FILE"
    sed -i 's/\bPGresult\b/PG::Result/g' "$POSTGRESQL_FILE"
    sed -i 's/\bPGError\b/PG::Error/g' "$POSTGRESQL_FILE"
    NEEDS_PATCH=1
  fi
  if grep -q "'panic'" "$POSTGRESQL_FILE"; then
    echo "Patching PostgreSQL adapter client_min_messages..."
    sed -i "s/'panic'/'error'/g" "$POSTGRESQL_FILE"
    NEEDS_PATCH=1
  fi
  if grep -q "d\.adsrc" "$POSTGRESQL_FILE"; then
    echo "Patching PostgreSQL adapter for PostgreSQL 12+ (adsrc -> pg_get_expr)..."
    sed -i 's/d\.adsrc/pg_get_expr(d.adbin, d.adrelid) as adsrc/g' "$POSTGRESQL_FILE"
    NEEDS_PATCH=1
  fi
  if [ $NEEDS_PATCH -eq 1 ]; then
    echo "PostgreSQL adapter patch applied successfully"
  fi
fi

# Patch 4: Fix Arel Integer visitor for Rails 3.x
AREL_VISITOR_FILE="$AREL_DIR/lib/arel/visitors/to_sql.rb"
if [ -f "$AREL_VISITOR_FILE" ]; then
  if grep -q "visit_Integer" "$AREL_VISITOR_FILE"; then
    echo "Arel visitor already patched for Integer support"
  else
    echo "Patching Arel visitor for Integer/Fixnum support..."
    # Add visit_Integer and visit_Fixnum methods to ToSql visitor
    cat >> "$AREL_VISITOR_FILE" << 'EOFARELPATCH'

    # Patch for Ruby 2.7+ where Fixnum is unified with Integer
    def visit_Integer o
      o.to_s
    end

    # Preserve Fixnum support for older Ruby versions
    def visit_Fixnum o
      o.to_s
    end
EOFARELPATCH
    echo "Arel visitor patch applied successfully"
  fi
fi

echo "All patches applied successfully!"
