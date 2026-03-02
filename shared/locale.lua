Locales = Locales or {}

function L(key, ...)
    local lang = Config and Config.Locale or 'pl'
    local dict = Locales[lang] or Locales['pl'] or {}
    local value = dict[key] or ('[' .. key .. ']')
    if select('#', ...) > 0 then
        return string.format(value, ...)
    end
    return value
end
