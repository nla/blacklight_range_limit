# Additional helper methods used by view templates inside this plugin.
module RangeLimitHelper
  def range_limit_url(options = {})
    main_app.url_for(search_state.to_h.merge(action: 'range_limit').merge(options))
  end

  # type is 'begin' or 'end'
  def render_range_input(solr_field, type, input_label = nil, maxlength=4)
    type = type.to_s

    default = params["range"][solr_field][type] if params["range"] && params["range"][solr_field] && params["range"][solr_field][type]

    html = number_field_tag("range[#{solr_field}][#{type}]", default, :maxlength=>maxlength, :class => "form-control text-center range_#{type}")
    html += label_tag("range[#{solr_field}][#{type}]", input_label, class: 'sr-only visually-hidden') if input_label.present?
    html
  end

  # type is 'min' or 'max'
  # Returns smallest and largest value in current result set, if available
  # from stats component response.
  def range_results_endpoint(solr_field, type)
    stats = stats_for_field(solr_field)

    return nil unless stats
    # StatsComponent returns weird min/max when there are in
    # fact no values
    return nil if @response.total == stats["missing"]

    return stats[type].to_s.gsub(/\.0+/, '')
  end

  def range_display(solr_field, my_params = params)
    return "" unless my_params[:range] && my_params[:range][solr_field]

    hash = my_params[:range][solr_field]

    if hash["missing"]
      return t('blacklight.range_limit.missing')
    elsif hash["begin"] || hash["end"]
      if hash["begin"] == hash["end"]
        return t(
          'blacklight.range_limit.single_html',
          begin: format_range_display_value(hash['begin'], solr_field),
          begin_value: hash['begin']
        )
      else
        return t(
          'blacklight.range_limit.range_html',
          begin: format_range_display_value(hash['begin'], solr_field),
          begin_value: hash['begin'],
          end: format_range_display_value(hash['end'], solr_field),
          end_value: hash['end']
        )
      end
    end

    ''
  end

  ##
  # A method that is meant to be overridden downstream to format how a range
  # label might be displayed to a user. By default it just returns the value
  # as rendered by the presenter
  def format_range_display_value(value, solr_field)
    if respond_to?(:facet_item_presenter)
      facet_item_presenter(facet_configuration_for_field(solr_field), value, solr_field).label
    else
      facet_display_value(solr_field, value)
    end
  end

  # Show the limit area if:
  # 1) we have a limit already set
  # OR
  # 2) stats show max > min, OR
  # 3) count > 0 if no stats available.
  def should_show_limit(solr_field)
    stats = stats_for_field(solr_field)

    (params["range"] && params["range"][solr_field]) ||
    (  stats &&
      stats["max"] > stats["min"]) ||
    ( !stats  && @response.total > 0 )
  end

  def stats_for_field(solr_field)
    @response["stats"]["stats_fields"][solr_field] if @response["stats"] && @response["stats"]["stats_fields"]
  end

  def stats_for_field?(solr_field)
    stats_for_field(solr_field).present?
  end

end
