# Monkey patch this fix until Formatador 0.2.3 is released
class Formatador
  def calculate_datum(header, hash)
    if !hash.keys.include?(header) && (splits = header.to_s.split('.')).length > 1
      datum = nil
      splits.each do |split|
        d = (datum||hash)
        datum = d[split] || d[split.to_sym] || ''
      end
    else
      datum = hash[header] || ''
    end
    datum
  end
end