/* @ds-bundle: {"format":4,"namespace":"NomnomDesignSystem_ec1f66","components":[{"name":"Badge","sourcePath":"components/core/Badge.jsx"},{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Card","sourcePath":"components/core/Card.jsx"},{"name":"Chip","sourcePath":"components/core/Chip.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"IconButton","sourcePath":"components/core/IconButton.jsx"},{"name":"Banner","sourcePath":"components/feedback/Banner.jsx"},{"name":"Dialog","sourcePath":"components/feedback/Dialog.jsx"},{"name":"ProgressBar","sourcePath":"components/feedback/ProgressBar.jsx"},{"name":"Sheet","sourcePath":"components/feedback/Sheet.jsx"},{"name":"SyncPill","sourcePath":"components/feedback/SyncPill.jsx"},{"name":"Checkbox","sourcePath":"components/forms/Checkbox.jsx"},{"name":"SegmentedControl","sourcePath":"components/forms/SegmentedControl.jsx"},{"name":"Stepper","sourcePath":"components/forms/Stepper.jsx"},{"name":"Switch","sourcePath":"components/forms/Switch.jsx"},{"name":"TextField","sourcePath":"components/forms/TextField.jsx"},{"name":"CaptureDock","sourcePath":"components/navigation/CaptureDock.jsx"},{"name":"ListRow","sourcePath":"components/navigation/ListRow.jsx"},{"name":"NavBar","sourcePath":"components/navigation/NavBar.jsx"},{"name":"DailySummary","sourcePath":"components/nutrition/DailySummary.jsx"},{"name":"FoodItemRow","sourcePath":"components/nutrition/FoodItemRow.jsx"},{"name":"MacroBar","sourcePath":"components/nutrition/MacroBar.jsx"},{"name":"MacroLine","sourcePath":"components/nutrition/MacroLine.jsx"},{"name":"MealPhoto","sourcePath":"components/nutrition/MealPhoto.jsx"},{"name":"MealRow","sourcePath":"components/nutrition/MealRow.jsx"}],"sourceHashes":{"components/core/Badge.jsx":"1a82ff90e014","components/core/Button.jsx":"05ad2e83e1c0","components/core/Card.jsx":"4153e47c9e77","components/core/Chip.jsx":"adf58b0d60a0","components/core/Icon.jsx":"98d8c9db46e4","components/core/IconButton.jsx":"7bcab256958e","components/feedback/Banner.jsx":"6ae6c1094d35","components/feedback/Dialog.jsx":"df110d2c12ea","components/feedback/ProgressBar.jsx":"90c1b05bde8e","components/feedback/Sheet.jsx":"941895a99347","components/feedback/SyncPill.jsx":"ad9b83138b5e","components/forms/Checkbox.jsx":"3f1c97ecdffe","components/forms/SegmentedControl.jsx":"2e681a8f207d","components/forms/Stepper.jsx":"e0cd515fb51d","components/forms/Switch.jsx":"53246af3fba2","components/forms/TextField.jsx":"bd9dd23ae574","components/navigation/CaptureDock.jsx":"24f01c595e4f","components/navigation/ListRow.jsx":"62dd03cd1085","components/navigation/NavBar.jsx":"f366b774d248","components/nutrition/DailySummary.jsx":"a49f28ffcb3c","components/nutrition/FoodItemRow.jsx":"5a0cbb2dc0cf","components/nutrition/MacroBar.jsx":"758dcc4840b6","components/nutrition/MacroLine.jsx":"408107168256","components/nutrition/MealPhoto.jsx":"6b1db3437226","components/nutrition/MealRow.jsx":"b08668dac1b0","ui_kits/duo/DuoFrame.jsx":"28e5fe7b18be","ui_kits/ios/CaptureScreen.jsx":"7f85c2b20c70","ui_kits/ios/ImportScreen.jsx":"d1ca80c7624f","ui_kits/ios/MealDetailScreen.jsx":"c28a26f8f347","ui_kits/ios/ReviewScreen.jsx":"d6262a04dd09","ui_kits/ios/ServingSheet.jsx":"f23d21f923d6","ui_kits/ios/SettingsScreen.jsx":"a12b0298d312","ui_kits/ios/SignInScreen.jsx":"8cf7d6083fec","ui_kits/ios/TodayScreen.jsx":"95c8842f9d90","ui_kits/ios/data.js":"f11980bbab8a","ui_kits/ios/ios-frame.jsx":"24642b887be3"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.NomnomDesignSystem_ec1f66 = window.NomnomDesignSystem_ec1f66 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Card({
  tone = 'surface',
  padding = 'lg',
  as: Tag = 'div',
  className = '',
  children,
  ...rest
}) {
  return /*#__PURE__*/React.createElement(Tag, _extends({
    className: 'nn-card nn-card--' + tone + ' nn-card--p-' + padding + ' ' + className
  }, rest), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Card.jsx", error: String((e && e.message) || e) }); }

// components/core/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Icon({
  name,
  size = 20,
  weight = 'regular',
  color,
  className = '',
  style,
  ...rest
}) {
  const cls = (weight === 'regular' ? 'ph' : 'ph-' + weight) + ' ph-' + name + ' nn-icon ' + className;
  return /*#__PURE__*/React.createElement("i", _extends({
    className: cls,
    "aria-hidden": "true",
    style: {
      fontSize: size,
      color,
      ...style
    }
  }, rest));
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/core/Badge.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const METHODS = {
  photo_ai: ['Photo AI', 'sparkle'],
  barcode: ['Barcode', 'barcode'],
  label_ocr: ['Label', 'scan'],
  manual: ['Manual', 'pencil-simple'],
  imported: ['Imported', 'download-simple']
};
function Badge({
  tone = 'neutral',
  icon,
  method,
  children,
  className = '',
  ...rest
}) {
  const m = method ? METHODS[method] : null;
  const ic = icon || m && m[1];
  return /*#__PURE__*/React.createElement("span", _extends({
    className: 'nn-badge nn-badge--' + tone + ' ' + className
  }, rest), ic ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: ic,
    size: 12,
    weight: "bold"
  }) : null, children || m && m[0]);
}
Object.assign(__ds_scope, { Badge });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Badge.jsx", error: String((e && e.message) || e) }); }

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Button({
  variant = 'primary',
  size = 'md',
  icon,
  iconRight,
  iconWeight = 'bold',
  fullWidth,
  loading,
  disabled,
  children,
  className = '',
  ...rest
}) {
  const cls = ['nn-btn', 'nn-btn--' + variant, 'nn-btn--' + size, fullWidth ? 'nn-btn--full' : '', className].join(' ');
  const iconSize = size === 'sm' ? 16 : size === 'lg' ? 22 : 18;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    className: cls,
    disabled: disabled || loading
  }, rest), loading ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "circle-notch",
    size: iconSize,
    weight: "bold",
    className: "nn-spin"
  }) : icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: iconSize,
    weight: iconWeight
  }) : null, children != null && children !== false ? /*#__PURE__*/React.createElement("span", {
    className: "nn-btn__label"
  }, children) : null, iconRight ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: iconRight,
    size: iconSize,
    weight: iconWeight
  }) : null);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Chip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Chip({
  selected,
  icon,
  size = 'md',
  children,
  className = '',
  ...rest
}) {
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    "aria-pressed": !!selected,
    className: 'nn-chip nn-chip--' + size + (selected ? ' is-selected' : '') + ' ' + className
  }, rest), icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 16
  }) : null, children);
}
Object.assign(__ds_scope, { Chip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Chip.jsx", error: String((e && e.message) || e) }); }

// components/core/IconButton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function IconButton({
  icon,
  label,
  variant = 'plain',
  size = 44,
  iconSize,
  weight = 'regular',
  className = '',
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    "aria-label": label,
    className: 'nn-iconbtn nn-iconbtn--' + variant + ' ' + className,
    style: {
      width: size,
      height: size,
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: iconSize || Math.round(size * 0.5),
    weight: weight
  }));
}
Object.assign(__ds_scope, { IconButton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/IconButton.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Banner.jsx
try { (() => {
function Banner({
  tone = 'neutral',
  icon,
  title,
  children,
  action,
  className = ''
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: 'nn-banner nn-banner--' + tone + ' ' + className,
    role: "status"
  }, icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 20,
    className: "nn-banner__icon"
  }) : null, /*#__PURE__*/React.createElement("div", {
    className: "nn-banner__body"
  }, title ? /*#__PURE__*/React.createElement("div", {
    className: "nn-banner__title"
  }, title) : null, children ? /*#__PURE__*/React.createElement("div", {
    className: "nn-banner__text"
  }, children) : null), action ? /*#__PURE__*/React.createElement("div", {
    className: "nn-banner__action"
  }, action) : null);
}
Object.assign(__ds_scope, { Banner });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Banner.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Dialog.jsx
try { (() => {
function Dialog({
  open,
  title,
  children,
  actions = [],
  onClose
}) {
  if (!open) return null;
  return /*#__PURE__*/React.createElement("div", {
    className: "nn-scrim nn-scrim--center",
    onClick: onClose
  }, /*#__PURE__*/React.createElement("div", {
    className: "nn-dialog",
    role: "alertdialog",
    "aria-modal": "true",
    "aria-label": title,
    onClick: e => e.stopPropagation()
  }, /*#__PURE__*/React.createElement("h2", {
    className: "nn-dialog__title"
  }, title), children ? /*#__PURE__*/React.createElement("div", {
    className: "nn-dialog__body"
  }, children) : null, /*#__PURE__*/React.createElement("div", {
    className: "nn-dialog__actions"
  }, actions.map((a, i) => /*#__PURE__*/React.createElement(__ds_scope.Button, {
    key: i,
    variant: a.variant || 'secondary',
    fullWidth: true,
    onClick: a.onClick
  }, a.label)))));
}
Object.assign(__ds_scope, { Dialog });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Dialog.jsx", error: String((e && e.message) || e) }); }

// components/feedback/ProgressBar.jsx
try { (() => {
function ProgressBar({
  value = 0,
  max = 100,
  tone = 'accent',
  size = 6,
  label,
  className = ''
}) {
  const pct = max > 0 ? Math.min(100, Math.max(0, value / max * 100)) : 0;
  return /*#__PURE__*/React.createElement("div", {
    className: 'nn-progress nn-progress--' + tone + ' ' + className,
    role: "progressbar",
    "aria-label": label,
    "aria-valuenow": Math.round(value),
    "aria-valuemin": 0,
    "aria-valuemax": max,
    style: {
      height: size
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: pct + '%'
    }
  }));
}
Object.assign(__ds_scope, { ProgressBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/ProgressBar.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Sheet.jsx
try { (() => {
function Sheet({
  open,
  onClose,
  title,
  children,
  footer,
  scrim = true,
  className = ''
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: 'nn-sheet-layer' + (open ? ' is-open' : ''),
    "aria-hidden": !open
  }, scrim ? /*#__PURE__*/React.createElement("div", {
    className: "nn-scrim",
    onClick: onClose
  }) : null, /*#__PURE__*/React.createElement("div", {
    className: 'nn-sheet ' + className,
    role: "dialog",
    "aria-label": typeof title === 'string' ? title : undefined
  }, /*#__PURE__*/React.createElement("div", {
    className: "nn-sheet__grabber"
  }), title ? /*#__PURE__*/React.createElement("div", {
    className: "nn-sheet__title"
  }, title) : null, /*#__PURE__*/React.createElement("div", {
    className: "nn-sheet__body"
  }, children), footer ? /*#__PURE__*/React.createElement("div", {
    className: "nn-sheet__footer"
  }, footer) : null));
}
Object.assign(__ds_scope, { Sheet });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Sheet.jsx", error: String((e && e.message) || e) }); }

// components/feedback/SyncPill.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
const STATES = {
  synced: ['cloud-check', 'Synced'],
  syncing: ['arrows-clockwise', 'Syncing…'],
  offline: ['cloud-slash', 'Offline · Queued']
};
function SyncPill({
  status = 'synced',
  queued,
  className = '',
  ...rest
}) {
  const s = STATES[status] || STATES.synced;
  const label = status === 'offline' && queued ? 'Offline · ' + queued + ' queued' : s[1];
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    className: 'nn-sync nn-sync--' + status + ' ' + className
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: s[0],
    size: 14,
    weight: "bold",
    className: status === 'syncing' ? 'nn-spin' : ''
  }), /*#__PURE__*/React.createElement("span", null, label));
}
Object.assign(__ds_scope, { SyncPill });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/SyncPill.jsx", error: String((e && e.message) || e) }); }

// components/forms/Checkbox.jsx
try { (() => {
function Checkbox({
  checked,
  onChange,
  label,
  description,
  trailing,
  dimUnchecked,
  disabled,
  className = ''
}) {
  return /*#__PURE__*/React.createElement("label", {
    className: 'nn-check' + (dimUnchecked ? ' nn-check--dim' : '') + (disabled ? ' is-disabled' : '') + ' ' + className
  }, /*#__PURE__*/React.createElement("input", {
    type: "checkbox",
    checked: !!checked,
    disabled: disabled,
    onChange: e => onChange && onChange(e.target.checked)
  }), /*#__PURE__*/React.createElement("span", {
    className: "nn-check__box"
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "check",
    weight: "bold",
    size: 14
  })), label || description ? /*#__PURE__*/React.createElement("span", {
    className: "nn-check__text"
  }, /*#__PURE__*/React.createElement("span", {
    className: "nn-check__label"
  }, label), description ? /*#__PURE__*/React.createElement("span", {
    className: "nn-check__desc"
  }, description) : null) : null, trailing ? /*#__PURE__*/React.createElement("span", {
    className: "nn-check__trailing"
  }, trailing) : null);
}
Object.assign(__ds_scope, { Checkbox });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Checkbox.jsx", error: String((e && e.message) || e) }); }

// components/forms/SegmentedControl.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function SegmentedControl({
  options = [],
  value,
  onChange,
  size = 'md',
  tone = 'default',
  fullWidth = true,
  numeric,
  className = '',
  ...rest
}) {
  const cls = ['nn-seg', 'nn-seg--' + size, 'nn-seg--' + tone, fullWidth ? 'nn-seg--full' : '', className].join(' ');
  return /*#__PURE__*/React.createElement("div", _extends({
    role: "tablist",
    className: cls
  }, rest), options.map(o => {
    const opt = o !== null && typeof o === 'object' ? o : {
      value: o,
      label: String(o)
    };
    const on = opt.value === value;
    return /*#__PURE__*/React.createElement("button", {
      key: String(opt.value),
      type: "button",
      role: "tab",
      "aria-selected": on,
      className: 'nn-seg__item' + (on ? ' is-selected' : '') + (numeric ? ' nn-num' : ''),
      onClick: () => onChange && onChange(opt.value)
    }, opt.icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
      name: opt.icon,
      size: size === 'sm' ? 14 : 16,
      weight: on ? 'bold' : 'regular'
    }) : null, opt.label);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/forms/Stepper.jsx
try { (() => {
function Stepper({
  value = 1,
  onChange,
  step = 0.5,
  min = 0,
  max = 99,
  format,
  label = 'Quantity',
  className = ''
}) {
  const set = v => onChange && onChange(Math.min(max, Math.max(min, Math.round(v * 100) / 100)));
  return /*#__PURE__*/React.createElement("div", {
    className: 'nn-stepper ' + className,
    role: "group",
    "aria-label": label
  }, /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": "Decrease",
    disabled: value <= min,
    onClick: () => set(value - step)
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "minus",
    weight: "bold",
    size: 16
  })), /*#__PURE__*/React.createElement("span", {
    className: "nn-stepper__value"
  }, format ? format(value) : value), /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": "Increase",
    disabled: value >= max,
    onClick: () => set(value + step)
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "plus",
    weight: "bold",
    size: 16
  })));
}
Object.assign(__ds_scope, { Stepper });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Stepper.jsx", error: String((e && e.message) || e) }); }

// components/forms/Switch.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function Switch({
  checked,
  onChange,
  disabled,
  label,
  className = '',
  ...rest
}) {
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    role: "switch",
    "aria-checked": !!checked,
    "aria-label": label,
    disabled: disabled,
    className: 'nn-switch' + (checked ? ' is-on' : '') + ' ' + className,
    onClick: () => onChange && onChange(!checked)
  }, rest), /*#__PURE__*/React.createElement("span", {
    className: "nn-switch__knob"
  }));
}
Object.assign(__ds_scope, { Switch });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/Switch.jsx", error: String((e && e.message) || e) }); }

// components/forms/TextField.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
function TextField({
  icon,
  value,
  onChange,
  placeholder,
  trailing,
  clearable,
  size = 'md',
  surface = 'fill',
  className = '',
  ...rest
}) {
  return /*#__PURE__*/React.createElement("label", {
    className: 'nn-field nn-field--' + size + ' nn-field--' + surface + ' ' + className
  }, icon ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 20,
    color: "var(--text-tertiary)"
  }) : null, /*#__PURE__*/React.createElement("input", _extends({
    className: "nn-field__input",
    value: value,
    placeholder: placeholder,
    onChange: e => onChange && onChange(e.target.value, e)
  }, rest)), clearable && value ? /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "nn-field__clear",
    "aria-label": "Clear",
    onClick: () => onChange && onChange('')
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "x-circle",
    weight: "fill",
    size: 18
  })) : null, trailing);
}
Object.assign(__ds_scope, { TextField });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/forms/TextField.jsx", error: String((e && e.message) || e) }); }

// components/navigation/CaptureDock.jsx
try { (() => {
function CaptureDock({
  onSnap,
  onBarcode,
  onManual,
  compact,
  className = ''
}) {
  return /*#__PURE__*/React.createElement("div", {
    className: 'nn-dock' + (compact ? ' nn-dock--compact' : '') + ' ' + className
  }, /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "nn-dock__side",
    onClick: onBarcode
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "barcode",
    size: 24
  }), /*#__PURE__*/React.createElement("span", null, "Barcode")), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "nn-dock__snap",
    "aria-label": "Snap plate",
    onClick: onSnap
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "camera",
    size: compact ? 26 : 30,
    weight: "fill"
  })), /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "nn-dock__side",
    onClick: onManual
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "pencil-simple",
    size: 24
  }), /*#__PURE__*/React.createElement("span", null, "Manual")));
}
Object.assign(__ds_scope, { CaptureDock });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/CaptureDock.jsx", error: String((e && e.message) || e) }); }

// components/navigation/ListRow.jsx
try { (() => {
function ListRow({
  icon,
  title,
  subtitle,
  value,
  chevron,
  trailing,
  tone = 'default',
  onClick,
  className = ''
}) {
  const Tag = onClick ? 'button' : 'div';
  return /*#__PURE__*/React.createElement(Tag, {
    type: onClick ? 'button' : undefined,
    className: 'nn-row nn-row--' + tone + ' ' + className,
    onClick: onClick
  }, icon ? /*#__PURE__*/React.createElement("span", {
    className: "nn-row__icon"
  }, /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: icon,
    size: 18
  })) : null, /*#__PURE__*/React.createElement("span", {
    className: "nn-row__text"
  }, /*#__PURE__*/React.createElement("span", {
    className: "nn-row__title"
  }, title), subtitle ? /*#__PURE__*/React.createElement("span", {
    className: "nn-row__subtitle"
  }, subtitle) : null), value ? /*#__PURE__*/React.createElement("span", {
    className: "nn-row__value"
  }, value) : null, trailing, chevron ? /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "caret-right",
    size: 14,
    weight: "bold",
    color: "var(--text-tertiary)"
  }) : null);
}
Object.assign(__ds_scope, { ListRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/ListRow.jsx", error: String((e && e.message) || e) }); }

// components/navigation/NavBar.jsx
try { (() => {
function NavBar({
  title,
  largeTitle,
  subtitle,
  leading,
  trailing,
  className = ''
}) {
  return /*#__PURE__*/React.createElement("header", {
    className: 'nn-nav ' + className
  }, /*#__PURE__*/React.createElement("div", {
    className: "nn-nav__bar"
  }, /*#__PURE__*/React.createElement("div", {
    className: "nn-nav__side"
  }, leading), title ? /*#__PURE__*/React.createElement("div", {
    className: "nn-nav__title"
  }, title) : null, /*#__PURE__*/React.createElement("div", {
    className: "nn-nav__side nn-nav__side--end"
  }, trailing)), largeTitle ? /*#__PURE__*/React.createElement("h1", {
    className: "nn-nav__large"
  }, largeTitle) : null, subtitle ? /*#__PURE__*/React.createElement("div", {
    className: "nn-nav__subtitle"
  }, subtitle) : null);
}
Object.assign(__ds_scope, { NavBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/navigation/NavBar.jsx", error: String((e && e.message) || e) }); }

// components/nutrition/FoodItemRow.jsx
try { (() => {
const PORTIONS = [0.5, 0.75, 1, 1.25, 1.5, 2];
function FoodItemRow({
  name,
  serving,
  kcal = 0,
  confidence,
  multiplier = 1,
  onMultiplier,
  expanded,
  onToggle,
  onSwap,
  onRemove,
  threshold = 0.76,
  className = ''
}) {
  const low = confidence != null && confidence < threshold;
  return /*#__PURE__*/React.createElement("div", {
    className: 'nn-food' + (expanded ? ' is-expanded' : '') + ' ' + className
  }, /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "nn-food__head",
    "aria-expanded": !!expanded,
    onClick: onToggle
  }, /*#__PURE__*/React.createElement("span", {
    className: "nn-food__main"
  }, /*#__PURE__*/React.createElement("span", {
    className: "nn-food__name"
  }, name, low ? /*#__PURE__*/React.createElement(__ds_scope.Badge, {
    tone: "check",
    icon: "question"
  }, "Check") : null), /*#__PURE__*/React.createElement("span", {
    className: "nn-food__serving"
  }, serving)), /*#__PURE__*/React.createElement("span", {
    className: 'nn-food__mult nn-num' + (multiplier !== 1 ? ' is-changed' : '')
  }, multiplier, "\xD7"), /*#__PURE__*/React.createElement("span", {
    className: "nn-food__kcal"
  }, /*#__PURE__*/React.createElement("span", null, Math.round(kcal * multiplier)), /*#__PURE__*/React.createElement("i", null, "kcal"))), expanded ? /*#__PURE__*/React.createElement("div", {
    className: "nn-food__panel"
  }, /*#__PURE__*/React.createElement(__ds_scope.SegmentedControl, {
    size: "sm",
    numeric: true,
    options: PORTIONS.map(p => ({
      value: p,
      label: p + '×'
    })),
    value: multiplier,
    onChange: onMultiplier,
    "aria-label": "Portion"
  }), /*#__PURE__*/React.createElement("div", {
    className: "nn-food__actions"
  }, /*#__PURE__*/React.createElement(__ds_scope.Button, {
    size: "sm",
    variant: "ghost",
    icon: "swap",
    onClick: onSwap
  }, "Swap"), /*#__PURE__*/React.createElement(__ds_scope.Button, {
    size: "sm",
    variant: "ghost",
    icon: "trash",
    onClick: onRemove
  }, "Remove"))) : null);
}
Object.assign(__ds_scope, { FoodItemRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/nutrition/FoodItemRow.jsx", error: String((e && e.message) || e) }); }

// components/nutrition/MacroBar.jsx
try { (() => {
const LABELS = {
  protein: 'Protein',
  carbs: 'Carbs',
  fat: 'Fat'
};
function MacroBar({
  macro = 'protein',
  value = 0,
  target,
  label,
  compact,
  className = ''
}) {
  const name = label || LABELS[macro];
  return /*#__PURE__*/React.createElement("div", {
    className: 'nn-macrobar' + (compact ? ' nn-macrobar--compact' : '') + ' ' + className
  }, /*#__PURE__*/React.createElement("div", {
    className: "nn-macrobar__head"
  }, /*#__PURE__*/React.createElement("span", {
    className: "nn-macrobar__label"
  }, name), /*#__PURE__*/React.createElement("span", {
    className: "nn-macrobar__value"
  }, Math.round(value), /*#__PURE__*/React.createElement("i", null, target ? '/' + target + 'g' : 'g'))), /*#__PURE__*/React.createElement(__ds_scope.ProgressBar, {
    tone: macro,
    value: value,
    max: target || value || 1,
    label: name
  }));
}
Object.assign(__ds_scope, { MacroBar });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/nutrition/MacroBar.jsx", error: String((e && e.message) || e) }); }

// components/nutrition/DailySummary.jsx
try { (() => {
const fmt = n => Math.round(n).toLocaleString('en-US');
function DailySummary({
  kcal = 0,
  target = 2000,
  protein = {},
  carbs = {},
  fat = {},
  micros = [],
  defaultExpanded = false,
  compact,
  className = ''
}) {
  const [open, setOpen] = React.useState(defaultExpanded);
  const left = target - kcal;
  return /*#__PURE__*/React.createElement(__ds_scope.Card, {
    className: 'nn-summary' + (compact ? ' nn-summary--compact' : '') + ' ' + className,
    padding: compact ? 'md' : 'lg'
  }, /*#__PURE__*/React.createElement("div", {
    className: "nn-summary__top"
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "nn-summary__kcal"
  }, fmt(kcal).split(',').map((p, i) => /*#__PURE__*/React.createElement(React.Fragment, {
    key: i
  }, i ? /*#__PURE__*/React.createElement("span", {
    className: "nn-sep"
  }, ",") : null, p))), compact ? null : /*#__PURE__*/React.createElement("div", {
    className: "nn-summary__of"
  }, "of ", fmt(target), " kcal")), /*#__PURE__*/React.createElement("div", {
    className: "nn-summary__left"
  }, /*#__PURE__*/React.createElement("span", {
    className: "nn-num"
  }, fmt(Math.abs(left))), left >= 0 ? ' left' : ' over')), /*#__PURE__*/React.createElement(__ds_scope.ProgressBar, {
    tone: "accent",
    size: compact ? 8 : 10,
    value: kcal,
    max: target,
    label: "Calories"
  }), /*#__PURE__*/React.createElement("div", {
    className: "nn-summary__macros"
  }, /*#__PURE__*/React.createElement(__ds_scope.MacroBar, {
    macro: "protein",
    value: protein.value,
    target: protein.target,
    compact: compact
  }), /*#__PURE__*/React.createElement(__ds_scope.MacroBar, {
    macro: "carbs",
    value: carbs.value,
    target: carbs.target,
    compact: compact
  }), /*#__PURE__*/React.createElement(__ds_scope.MacroBar, {
    macro: "fat",
    value: fat.value,
    target: fat.target,
    compact: compact
  })), micros.length > 0 && !compact && open ? /*#__PURE__*/React.createElement("dl", {
    className: "nn-summary__micros"
  }, micros.map(m => /*#__PURE__*/React.createElement("div", {
    key: m.label
  }, /*#__PURE__*/React.createElement("dt", null, m.label), /*#__PURE__*/React.createElement("dd", null, m.value)))) : null, micros.length > 0 && !compact ? /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: "nn-summary__toggle",
    "aria-expanded": open,
    onClick: () => setOpen(!open)
  }, open ? 'Fewer nutrients' : 'More nutrients', /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: open ? 'caret-up' : 'caret-down',
    size: 12,
    weight: "bold"
  })) : null);
}
Object.assign(__ds_scope, { DailySummary });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/nutrition/DailySummary.jsx", error: String((e && e.message) || e) }); }

// components/nutrition/MacroLine.jsx
try { (() => {
function MacroLine({
  protein,
  carbs,
  fat,
  size = 'sm',
  className = ''
}) {
  const r = v => v == null ? '–' : Math.round(v);
  return /*#__PURE__*/React.createElement("span", {
    className: 'nn-macroline nn-macroline--' + size + ' nn-num ' + className
  }, /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("b", {
    className: "nn-m-protein"
  }, "P"), r(protein)), /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("b", {
    className: "nn-m-carbs"
  }, "C"), r(carbs)), /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("b", {
    className: "nn-m-fat"
  }, "F"), r(fat)));
}
Object.assign(__ds_scope, { MacroLine });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/nutrition/MacroLine.jsx", error: String((e && e.message) || e) }); }

// components/nutrition/MealPhoto.jsx
try { (() => {
function MealPhoto({
  src,
  alt,
  size = 56,
  radius,
  label,
  tone = 'light',
  className = '',
  style
}) {
  const s = {
    width: size,
    height: size,
    borderRadius: radius,
    ...(src ? {
      backgroundImage: 'url(' + src + ')'
    } : {}),
    ...style
  };
  const n = typeof size === 'number' ? size : 96;
  return /*#__PURE__*/React.createElement("div", {
    className: 'nn-photo nn-photo--' + tone + (src ? ' has-src' : '') + ' ' + className,
    role: "img",
    "aria-label": alt || label || 'Meal photo',
    style: s
  }, src ? null : /*#__PURE__*/React.createElement(__ds_scope.Icon, {
    name: "image",
    size: Math.max(18, Math.min(32, Math.round(n * 0.36)))
  }), !src && label ? /*#__PURE__*/React.createElement("span", null, label) : null);
}
Object.assign(__ds_scope, { MealPhoto });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/nutrition/MealPhoto.jsx", error: String((e && e.message) || e) }); }

// components/nutrition/MealRow.jsx
try { (() => {
function MealRow({
  title,
  time,
  mealType,
  kcal,
  protein,
  carbs,
  fat,
  method,
  photo,
  pending,
  selected,
  onClick,
  className = ''
}) {
  return /*#__PURE__*/React.createElement("button", {
    type: "button",
    className: 'nn-meal' + (selected ? ' is-selected' : '') + (pending ? ' is-pending' : '') + ' ' + className,
    onClick: onClick
  }, /*#__PURE__*/React.createElement(__ds_scope.MealPhoto, {
    src: photo,
    size: 56
  }), /*#__PURE__*/React.createElement("span", {
    className: "nn-meal__main"
  }, /*#__PURE__*/React.createElement("span", {
    className: "nn-meal__title"
  }, title), /*#__PURE__*/React.createElement("span", {
    className: "nn-meal__meta"
  }, [mealType, time].filter(Boolean).join(' · ')), /*#__PURE__*/React.createElement("span", {
    className: "nn-meal__foot"
  }, pending ? /*#__PURE__*/React.createElement(__ds_scope.Badge, {
    tone: "pending",
    icon: "clock"
  }, "Pending AI analysis") : /*#__PURE__*/React.createElement(__ds_scope.Badge, {
    method: method
  }), pending ? null : /*#__PURE__*/React.createElement(__ds_scope.MacroLine, {
    protein: protein,
    carbs: carbs,
    fat: fat
  }))), /*#__PURE__*/React.createElement("span", {
    className: "nn-meal__kcal"
  }, /*#__PURE__*/React.createElement("span", null, pending ? '–' : Math.round(kcal)), /*#__PURE__*/React.createElement("i", null, "kcal")));
}
Object.assign(__ds_scope, { MealRow });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/nutrition/MealRow.jsx", error: String((e && e.message) || e) }); }

// ui_kits/duo/DuoFrame.jsx
try { (() => {
(function () {
  const {
    Icon,
    NavBar,
    Card,
    MacroBar
  } = window.NomnomDesignSystem_ec1f66;

  // iPhone Duo: folded 5.4" cover (466 × 678 pt) or unfolded 7.6" inner display (890 × 626 pt, two panes).
  function DuoFrame({
    unfolded,
    left,
    right,
    children
  }) {
    return /*#__PURE__*/React.createElement("div", {
      className: 'duo' + (unfolded ? ' duo--unfolded' : ''),
      style: {
        width: unfolded ? 890 : 466,
        height: unfolded ? 626 : 678
      }
    }, /*#__PURE__*/React.createElement("div", {
      className: "duo__status"
    }, /*#__PURE__*/React.createElement("span", null, "9:41"), /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement(Icon, {
      name: "cell-signal-full",
      weight: "fill",
      size: 16
    }), /*#__PURE__*/React.createElement(Icon, {
      name: "wifi-high",
      weight: "bold",
      size: 16
    }), /*#__PURE__*/React.createElement(Icon, {
      name: "battery-full",
      weight: "fill",
      size: 22
    }))), unfolded ? null : /*#__PURE__*/React.createElement("div", {
      className: "duo__island"
    }), unfolded ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
      className: "duo__pane"
    }, left), /*#__PURE__*/React.createElement("div", {
      className: "duo__hinge"
    }), /*#__PURE__*/React.createElement("div", {
      className: "duo__pane"
    }, right)) : /*#__PURE__*/React.createElement("div", {
      className: "duo__pane"
    }, children), /*#__PURE__*/React.createElement("div", {
      className: "duo__home"
    }));
  }

  // Default right pane on Today when no meal is selected.
  function WeekTrend() {
    const D = window.NN_DATA,
      w = D.week,
      target = D.targets.kcal;
    const max = Math.max.apply(null, w.kcal.concat(target)) * 1.08;
    const done = w.kcal.slice(0, 6);
    const avg = Math.round(done.reduce((a, b) => a + b, 0) / done.length);
    return /*#__PURE__*/React.createElement("div", {
      className: "scr"
    }, /*#__PURE__*/React.createElement("div", {
      className: "scr__top"
    }, /*#__PURE__*/React.createElement(NavBar, {
      largeTitle: "This week",
      subtitle: w.range
    })), /*#__PURE__*/React.createElement("div", {
      className: "scr__scroll"
    }, /*#__PURE__*/React.createElement(Card, null, /*#__PURE__*/React.createElement("span", {
      className: "kcal-lg"
    }, avg.toLocaleString('en-US'), /*#__PURE__*/React.createElement("small", null, "avg kcal a day")), /*#__PURE__*/React.createElement("div", {
      className: "week"
    }, /*#__PURE__*/React.createElement("div", {
      className: "week__target",
      style: {
        bottom: target / max * 100 + '%'
      }
    }, /*#__PURE__*/React.createElement("span", null, target.toLocaleString('en-US'))), w.kcal.map((k, i) => /*#__PURE__*/React.createElement("div", {
      key: i,
      className: 'week__col' + (i === 6 ? ' is-today' : '')
    }, /*#__PURE__*/React.createElement("div", {
      className: "week__bar",
      style: {
        height: k / max * 100 + '%'
      }
    }), /*#__PURE__*/React.createElement("span", null, w.days[i]))))), /*#__PURE__*/React.createElement(Card, null, /*#__PURE__*/React.createElement("div", {
      className: "detail__macros",
      style: {
        marginTop: 0
      }
    }, /*#__PURE__*/React.createElement(MacroBar, {
      macro: "protein",
      value: w.avg.protein,
      target: D.targets.protein
    }), /*#__PURE__*/React.createElement(MacroBar, {
      macro: "carbs",
      value: w.avg.carbs,
      target: D.targets.carbs
    }), /*#__PURE__*/React.createElement(MacroBar, {
      macro: "fat",
      value: w.avg.fat,
      target: D.targets.fat
    }))), /*#__PURE__*/React.createElement("p", {
      className: "empty-note"
    }, "Tap a meal on the left to see its breakdown here.")));
  }
  Object.assign(window, {
    DuoFrame,
    WeekTrend
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/duo/DuoFrame.jsx", error: String((e && e.message) || e) }); }

// ui_kits/ios/CaptureScreen.jsx
try { (() => {
(function () {
  const {
    IconButton,
    Chip,
    SegmentedControl,
    TextField,
    Card,
    Icon,
    MealPhoto,
    ListRow
  } = window.NomnomDesignSystem_ec1f66;
  const MODES = [{
    value: 'photo',
    label: 'Photo AI',
    icon: 'sparkle'
  }, {
    value: 'barcode',
    label: 'Barcode',
    icon: 'barcode'
  }, {
    value: 'manual',
    label: 'Manual',
    icon: 'pencil-simple'
  }];
  const HINTS = ['light oil', 'half rice', 'no sauce', 'shared plate'];
  function CaptureScreen({
    mode = 'photo',
    onMode,
    onClose,
    onCaptured,
    onAdd,
    onEstimate,
    offline,
    quotaLeft
  }) {
    const D = window.NN_DATA;
    const [phase, setPhase] = React.useState('live');
    const [hints, setHints] = React.useState([]);
    const [q, setQ] = React.useState('');
    const [food, setFood] = React.useState(null);
    const [sheet, setSheet] = React.useState(false);
    const dark = mode !== 'manual';
    React.useEffect(() => {
      setSheet(false);
      if (mode !== 'barcode') return undefined;
      const t = setTimeout(() => {
        setFood(D.product);
        setSheet(true);
      }, 1600);
      return () => clearTimeout(t);
    }, [mode]);
    const shoot = () => {
      if (offline) {
        onCaptured && onCaptured({
          pending: true
        });
        return;
      }
      setPhase('analyzing');
      setTimeout(() => onCaptured && onCaptured({
        pending: false
      }), 2100);
    };
    const toggleHint = h => setHints(hints.includes(h) ? hints.filter(x => x !== h) : hints.concat(h));
    const term = q.trim().toLowerCase();
    const results = D.recents.filter(f => f.name.toLowerCase().includes(term));
    return /*#__PURE__*/React.createElement("div", {
      className: 'scr cap' + (dark ? ' cap--dark' : '')
    }, dark ? /*#__PURE__*/React.createElement(MealPhoto, {
      tone: "dark",
      label: phase === 'analyzing' ? 'captured photo' : 'camera viewfinder',
      className: 'cap__view' + (mode === 'barcode' ? ' cap__view--bare' : '')
    }) : null, /*#__PURE__*/React.createElement("div", {
      className: "scr__top cap__bar"
    }, /*#__PURE__*/React.createElement(IconButton, {
      icon: "x",
      label: "Close",
      variant: dark ? 'glass' : 'filled',
      onClick: onClose
    }), mode === 'manual' ? /*#__PURE__*/React.createElement("span", {
      className: "cap__heading"
    }, "Add manually") : null, dark ? /*#__PURE__*/React.createElement(IconButton, {
      icon: mode === 'photo' ? 'lightning-slash' : 'flashlight',
      label: "Light",
      variant: "glass"
    }) : /*#__PURE__*/React.createElement("span", {
      style: {
        width: 44
      }
    })), mode === 'photo' && phase === 'live' ? /*#__PURE__*/React.createElement("div", {
      className: "cap__bottom"
    }, offline ? /*#__PURE__*/React.createElement("div", {
      className: "cap__note"
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "cloud-slash",
      size: 14,
      weight: "bold"
    }), "Offline. Your photo is saved now and analysed later.") : null, !offline && quotaLeft != null && quotaLeft <= 3 ? /*#__PURE__*/React.createElement("div", {
      className: "cap__note"
    }, /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("span", {
      className: "nn-num"
    }, quotaLeft), " photo scans left today")) : null, /*#__PURE__*/React.createElement("div", {
      className: "cap__hints"
    }, /*#__PURE__*/React.createElement(Chip, {
      size: "sm",
      icon: "microphone"
    }, "Add a hint"), HINTS.map(h => /*#__PURE__*/React.createElement(Chip, {
      key: h,
      size: "sm",
      selected: hints.includes(h),
      onClick: () => toggleHint(h)
    }, h))), /*#__PURE__*/React.createElement("div", {
      className: "cap__shutter-row"
    }, /*#__PURE__*/React.createElement(IconButton, {
      icon: "images",
      label: "Photo library",
      variant: "glass",
      size: 48
    }), /*#__PURE__*/React.createElement("button", {
      type: "button",
      className: "shutter",
      "aria-label": "Take photo",
      onClick: shoot
    }, /*#__PURE__*/React.createElement("i", null)), /*#__PURE__*/React.createElement("span", {
      style: {
        width: 48
      }
    }))) : null, mode === 'photo' && phase === 'analyzing' ? /*#__PURE__*/React.createElement("div", {
      className: "cap__analyzing"
    }, /*#__PURE__*/React.createElement("div", {
      className: "cap__analyzing-title"
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "sparkle",
      size: 18,
      weight: "fill"
    }), "Looking at your plate"), /*#__PURE__*/React.createElement("div", {
      className: "nn-shimmer cap__skel",
      style: {
        width: '78%'
      }
    }), /*#__PURE__*/React.createElement("div", {
      className: "nn-shimmer cap__skel",
      style: {
        width: '56%'
      }
    }), /*#__PURE__*/React.createElement("div", {
      className: "nn-shimmer cap__skel",
      style: {
        width: '66%'
      }
    })) : null, mode === 'barcode' ? /*#__PURE__*/React.createElement("div", {
      className: "cap__scan"
    }, /*#__PURE__*/React.createElement("div", {
      className: "reticle"
    }, /*#__PURE__*/React.createElement("i", null)), /*#__PURE__*/React.createElement("div", {
      className: "cap__note"
    }, "Point at a barcode"), /*#__PURE__*/React.createElement(Chip, {
      size: "sm",
      icon: "scan"
    }, "No barcode? Snap the Nutrition Facts label")) : null, mode === 'manual' ? /*#__PURE__*/React.createElement("div", {
      className: "scr__scroll cap__manual"
    }, /*#__PURE__*/React.createElement(TextField, {
      icon: "magnifying-glass",
      placeholder: "Search foods or describe a meal",
      value: q,
      onChange: setQ,
      clearable: true,
      surface: "card"
    }), /*#__PURE__*/React.createElement("button", {
      type: "button",
      className: "estimate",
      onClick: () => onEstimate && onEstimate(q)
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "sparkle",
      size: 22,
      weight: "fill"
    }), /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("b", null, term ? 'Estimate "' + q.trim() + '" with AI' : 'Estimate with AI'), /*#__PURE__*/React.createElement("small", null, "Type it how you'd say it: 2 scrambled eggs in butter + sourdough toast")), /*#__PURE__*/React.createElement(Icon, {
      name: "caret-right",
      size: 14,
      weight: "bold"
    })), /*#__PURE__*/React.createElement("div", {
      className: "sec"
    }, /*#__PURE__*/React.createElement("div", {
      className: "sec__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, term ? 'Results' : 'Recent')), results.length ? /*#__PURE__*/React.createElement(Card, {
      padding: "none"
    }, results.map(f => /*#__PURE__*/React.createElement(ListRow, {
      key: f.name,
      title: f.name,
      subtitle: f.brand + ' · ' + f.servings[0].label,
      chevron: true,
      value: /*#__PURE__*/React.createElement("span", {
        className: "nn-num"
      }, Math.round(f.per100.kcal * f.servings[0].g / 100), " kcal"),
      onClick: () => {
        setFood(f);
        setSheet(true);
      }
    }))) : /*#__PURE__*/React.createElement("p", {
      className: "empty-note"
    }, "No saved foods match. Use Estimate with AI above."))) : null, phase === 'live' ? /*#__PURE__*/React.createElement("div", {
      className: "cap__modes"
    }, /*#__PURE__*/React.createElement(SegmentedControl, {
      tone: dark ? 'dark' : 'default',
      options: MODES,
      value: mode,
      onChange: onMode
    })) : null, /*#__PURE__*/React.createElement(window.ServingSheet, {
      open: sheet,
      food: food,
      method: mode === 'barcode' ? 'barcode' : 'manual',
      onClose: () => setSheet(false),
      onAdd: m => {
        setSheet(false);
        onAdd && onAdd(m);
      }
    }));
  }
  Object.assign(window, {
    CaptureScreen
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios/CaptureScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/ios/ImportScreen.jsx
try { (() => {
(function () {
  const {
    NavBar,
    IconButton,
    Button,
    Card,
    ListRow,
    Banner,
    Badge,
    Checkbox,
    ProgressBar,
    Icon
  } = window.NomnomDesignSystem_ec1f66;
  const POLICIES = [['skip', 'Skip duplicates', 'Keep what is already in nomnom'], ['both', 'Keep both', 'Import everything, even if it repeats'], ['replace', 'Replace existing date', 'Imported days overwrite nomnom days']];
  function ImportScreen({
    onBack,
    onDone
  }) {
    const D = window.NN_DATA;
    const [step, setStep] = React.useState(1);
    const [policy, setPolicy] = React.useState('skip');
    const [pct, setPct] = React.useState(0);
    React.useEffect(() => {
      if (step !== 4) return undefined;
      const a = setTimeout(() => setPct(100), 60);
      const b = setTimeout(() => setStep(5), 1700);
      return () => {
        clearTimeout(a);
        clearTimeout(b);
      };
    }, [step]);
    const back = () => step > 1 && step < 4 ? setStep(step - 1) : onBack && onBack();
    return /*#__PURE__*/React.createElement("div", {
      className: "scr"
    }, /*#__PURE__*/React.createElement("div", {
      className: "scr__top"
    }, /*#__PURE__*/React.createElement(NavBar, {
      title: "Import history",
      leading: /*#__PURE__*/React.createElement(IconButton, {
        icon: step === 1 ? 'x' : 'caret-left',
        label: "Back",
        variant: "filled",
        size: 36,
        weight: "bold",
        iconSize: 16,
        onClick: back
      })
    }), step < 5 ? /*#__PURE__*/React.createElement("div", {
      className: "step"
    }, /*#__PURE__*/React.createElement("span", null, "Step ", step, " of 4"), /*#__PURE__*/React.createElement(ProgressBar, {
      tone: "neutral",
      size: 4,
      value: step,
      max: 4
    })) : null), step === 1 ? /*#__PURE__*/React.createElement("div", {
      className: "scr__scroll"
    }, /*#__PURE__*/React.createElement("h1", {
      className: "detail__title"
    }, "Where is your history?"), /*#__PURE__*/React.createElement(Card, {
      padding: "none"
    }, /*#__PURE__*/React.createElement(ListRow, {
      icon: "file-zip",
      title: "MyFitnessPal",
      subtitle: "Export .zip or Nutrition-Summary .csv",
      chevron: true,
      onClick: () => setStep(2)
    }), /*#__PURE__*/React.createElement(ListRow, {
      icon: "heartbeat",
      title: "Apple Health",
      subtitle: "Read calories and macros already in Health",
      chevron: true,
      onClick: () => setStep(2)
    }))) : null, step === 2 ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
      className: "scr__scroll"
    }, /*#__PURE__*/React.createElement("h1", {
      className: "detail__title"
    }, "Here's what we found"), /*#__PURE__*/React.createElement(Banner, {
      tone: "info",
      icon: "info",
      title: "MyFitnessPal exports meal totals"
    }, "You get one entry per meal per day (Breakfast, Lunch, Dinner, Snacks) with full calories and macros. Individual foods aren't in their export."), /*#__PURE__*/React.createElement("div", {
      className: "btn-row"
    }, ['Date', 'Meal', 'Calories', 'Protein', 'Carbs', 'Fat'].map(c => /*#__PURE__*/React.createElement(Badge, {
      key: c,
      tone: "positive",
      icon: "check"
    }, c))), /*#__PURE__*/React.createElement(Card, {
      padding: "md"
    }, /*#__PURE__*/React.createElement("table", {
      className: "tbl"
    }, /*#__PURE__*/React.createElement("thead", null, /*#__PURE__*/React.createElement("tr", null, /*#__PURE__*/React.createElement("th", null, "Date"), /*#__PURE__*/React.createElement("th", null, "Meal"), /*#__PURE__*/React.createElement("th", null, "kcal"), /*#__PURE__*/React.createElement("th", null, "P"), /*#__PURE__*/React.createElement("th", null, "C"), /*#__PURE__*/React.createElement("th", null, "F"))), /*#__PURE__*/React.createElement("tbody", null, D.importRows.map((r, i) => /*#__PURE__*/React.createElement("tr", {
      key: i
    }, r.map((c, j) => /*#__PURE__*/React.createElement("td", {
      key: j
    }, c))))))), /*#__PURE__*/React.createElement("p", {
      className: "empty-note"
    }, "421 meals between 3 Mar and 24 Nov 2026.")), /*#__PURE__*/React.createElement("div", {
      className: "scr__footer"
    }, /*#__PURE__*/React.createElement(Button, {
      size: "lg",
      fullWidth: true,
      onClick: () => setStep(3)
    }, "Looks right"))) : null, step === 3 ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
      className: "scr__scroll"
    }, /*#__PURE__*/React.createElement("h1", {
      className: "detail__title"
    }, "If a meal is already here"), /*#__PURE__*/React.createElement(Card, {
      padding: "md",
      style: {
        paddingTop: 6,
        paddingBottom: 6
      }
    }, POLICIES.map(p => /*#__PURE__*/React.createElement(Checkbox, {
      key: p[0],
      checked: policy === p[0],
      onChange: () => setPolicy(p[0]),
      label: p[1],
      description: p[2]
    })))), /*#__PURE__*/React.createElement("div", {
      className: "scr__footer"
    }, /*#__PURE__*/React.createElement(Button, {
      variant: "accent",
      size: "lg",
      fullWidth: true,
      onClick: () => {
        setPct(0);
        setStep(4);
      }
    }, "Import ", /*#__PURE__*/React.createElement("span", {
      className: "nn-num"
    }, "421"), " meals"))) : null, step === 4 ? /*#__PURE__*/React.createElement("div", {
      className: "receipt"
    }, /*#__PURE__*/React.createElement("h2", null, "Importing"), /*#__PURE__*/React.createElement("p", null, "This stays on your iPhone until it syncs."), /*#__PURE__*/React.createElement("div", {
      style: {
        width: 220,
        marginTop: 12
      }
    }, /*#__PURE__*/React.createElement(ProgressBar, {
      tone: "accent",
      size: 8,
      value: pct,
      max: 100
    }))) : null, step === 5 ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("div", {
      className: "receipt"
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "check-circle",
      size: 44,
      weight: "fill",
      color: "var(--positive)"
    }), /*#__PURE__*/React.createElement("h2", null, "Import finished"), /*#__PURE__*/React.createElement("p", null, /*#__PURE__*/React.createElement("span", {
      className: "nn-num"
    }, "412"), " meals imported \xB7 ", /*#__PURE__*/React.createElement("span", {
      className: "nn-num"
    }, "9"), " duplicates skipped")), /*#__PURE__*/React.createElement("div", {
      className: "scr__footer"
    }, /*#__PURE__*/React.createElement(Button, {
      size: "lg",
      fullWidth: true,
      onClick: onDone
    }, "Back to Today"))) : null);
  }
  Object.assign(window, {
    ImportScreen
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios/ImportScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/ios/MealDetailScreen.jsx
try { (() => {
(function () {
  const {
    NavBar,
    IconButton,
    Button,
    Badge,
    MealPhoto,
    Card,
    MacroBar,
    ListRow,
    Banner
  } = window.NomnomDesignSystem_ec1f66;

  // Full screen on iPhone; `embedded` turns it into the right-pane inspector on iPhone Duo unfolded.
  function MealDetailScreen({
    meal,
    onBack,
    onDelete,
    embedded
  }) {
    const D = window.NN_DATA;
    if (!meal) return null;
    const hasPhoto = meal.method === 'photo_ai' || meal.pending;
    return /*#__PURE__*/React.createElement("div", {
      className: "scr"
    }, /*#__PURE__*/React.createElement("div", {
      className: "scr__top"
    }, /*#__PURE__*/React.createElement(NavBar, {
      leading: /*#__PURE__*/React.createElement(IconButton, {
        icon: embedded ? 'x' : 'caret-left',
        label: embedded ? 'Close' : 'Back',
        variant: "filled",
        size: 36,
        weight: "bold",
        iconSize: 16,
        onClick: onBack
      }),
      trailing: meal.pending ? null : /*#__PURE__*/React.createElement(Button, {
        size: "sm",
        variant: "secondary"
      }, "Edit")
    })), /*#__PURE__*/React.createElement("div", {
      className: "scr__scroll"
    }, hasPhoto ? /*#__PURE__*/React.createElement(MealPhoto, {
      label: "meal photo",
      radius: 28,
      style: {
        width: '100%',
        height: embedded ? 140 : 180
      }
    }) : null, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h1", {
      className: "detail__title"
    }, meal.title), /*#__PURE__*/React.createElement("div", {
      className: "detail__meta"
    }, meal.mealType, " \xB7 ", meal.time, meal.pending ? /*#__PURE__*/React.createElement(Badge, {
      tone: "pending",
      icon: "clock"
    }, "Pending AI analysis") : /*#__PURE__*/React.createElement(Badge, {
      method: meal.method
    }))), meal.pending ? /*#__PURE__*/React.createElement(Banner, {
      icon: "cloud-slash",
      title: "Saved on this iPhone"
    }, "We'll analyse this photo as soon as you're back online. Nothing else to do.") : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Card, null, /*#__PURE__*/React.createElement("span", {
      className: "kcal-lg"
    }, Math.round(meal.kcal), /*#__PURE__*/React.createElement("small", null, "kcal")), /*#__PURE__*/React.createElement("div", {
      className: "detail__macros"
    }, /*#__PURE__*/React.createElement(MacroBar, {
      macro: "protein",
      value: meal.protein
    }), /*#__PURE__*/React.createElement(MacroBar, {
      macro: "carbs",
      value: meal.carbs
    }), /*#__PURE__*/React.createElement(MacroBar, {
      macro: "fat",
      value: meal.fat
    }))), /*#__PURE__*/React.createElement("div", {
      className: "sec"
    }, /*#__PURE__*/React.createElement("div", {
      className: "sec__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, "Items")), /*#__PURE__*/React.createElement(Card, {
      padding: "none"
    }, (meal.items || []).map(i => /*#__PURE__*/React.createElement(ListRow, {
      key: i.name,
      title: i.name,
      subtitle: i.serving,
      value: /*#__PURE__*/React.createElement("span", {
        className: "nn-num"
      }, i.kcal)
    })))), /*#__PURE__*/React.createElement("div", {
      className: "sec"
    }, /*#__PURE__*/React.createElement("div", {
      className: "sec__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, "Nutrients")), /*#__PURE__*/React.createElement(Card, null, /*#__PURE__*/React.createElement("dl", {
      className: "micros"
    }, D.micros.map(m => /*#__PURE__*/React.createElement("div", {
      key: m.label
    }, /*#__PURE__*/React.createElement("dt", null, m.label), /*#__PURE__*/React.createElement("dd", null, m.value))))))), /*#__PURE__*/React.createElement(Button, {
      variant: "destructive",
      fullWidth: true,
      icon: "trash",
      onClick: () => onDelete && onDelete(meal)
    }, "Delete meal")));
  }
  Object.assign(window, {
    MealDetailScreen
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios/MealDetailScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/ios/ReviewScreen.jsx
try { (() => {
(function () {
  const {
    NavBar,
    IconButton,
    Button,
    SegmentedControl,
    MacroLine,
    MealPhoto,
    Card,
    FoodItemRow,
    Checkbox,
    Icon
  } = window.NomnomDesignSystem_ec1f66;

  // Shared state so the same parts can sit in one column (iPhone) or two panes (iPhone Duo unfolded).
  function useReview() {
    const D = window.NN_DATA;
    const [items, setItems] = React.useState(() => D.detected.map(d => ({
      ...d,
      mult: 1
    })));
    const [extras, setExtras] = React.useState(() => D.extras.map(e => ({
      ...e
    })));
    const firstLow = D.detected.find(d => d.confidence < 0.76);
    const [open, setOpen] = React.useState(firstLow ? firstLow.id : null);
    const [drawer, setDrawer] = React.useState(false);
    const [type, setType] = React.useState('Dinner');
    const [title, setTitle] = React.useState(D.detectedTitle);
    const tot = k => items.reduce((a, i) => a + i[k] * i.mult, 0) + extras.filter(e => e.on).reduce((a, e) => a + e[k], 0);
    const totals = {
      kcal: Math.round(tot('kcal')),
      protein: tot('p'),
      carbs: tot('c'),
      fat: tot('f')
    };
    const meal = () => ({
      title,
      mealType: type,
      method: 'photo_ai',
      ...totals,
      items: items.map(i => ({
        name: i.name,
        serving: i.mult === 1 ? i.serving : i.mult + '× ' + i.serving,
        kcal: Math.round(i.kcal * i.mult)
      })).concat(extras.filter(e => e.on).map(e => ({
        name: e.name,
        serving: e.serving,
        kcal: e.kcal
      })))
    });
    return {
      items,
      setItems,
      extras,
      setExtras,
      open,
      setOpen,
      drawer,
      setDrawer,
      type,
      setType,
      title,
      setTitle,
      totals,
      meal
    };
  }
  function ReviewHeader({
    r
  }) {
    return /*#__PURE__*/React.createElement("div", {
      className: "rev__head"
    }, /*#__PURE__*/React.createElement("label", {
      className: "rev__titlewrap"
    }, /*#__PURE__*/React.createElement("input", {
      className: "rev__title",
      value: r.title,
      onChange: e => r.setTitle(e.target.value),
      "aria-label": "Meal title"
    }), /*#__PURE__*/React.createElement(Icon, {
      name: "pencil-simple",
      size: 18
    })), /*#__PURE__*/React.createElement(SegmentedControl, {
      options: ['Breakfast', 'Lunch', 'Dinner', 'Snack'],
      value: r.type,
      onChange: r.setType
    }), /*#__PURE__*/React.createElement("div", {
      className: "rev__totals"
    }, /*#__PURE__*/React.createElement("span", {
      className: "kcal-lg"
    }, r.totals.kcal, /*#__PURE__*/React.createElement("small", null, "kcal")), /*#__PURE__*/React.createElement(MacroLine, {
      size: "md",
      protein: r.totals.protein,
      carbs: r.totals.carbs,
      fat: r.totals.fat
    })));
  }
  function ReviewItems({
    r
  }) {
    const upd = (id, patch) => r.setItems(r.items.map(i => i.id === id ? {
      ...i,
      ...patch
    } : i));
    return /*#__PURE__*/React.createElement("div", {
      className: "sec"
    }, /*#__PURE__*/React.createElement("div", {
      className: "sec__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, "On the plate"), /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, "Tap to adjust")), /*#__PURE__*/React.createElement(Card, {
      padding: "none"
    }, r.items.map(i => /*#__PURE__*/React.createElement(FoodItemRow, {
      key: i.id,
      name: i.name,
      serving: i.serving,
      kcal: i.kcal,
      confidence: i.confidence,
      multiplier: i.mult,
      onMultiplier: m => upd(i.id, {
        mult: m
      }),
      expanded: r.open === i.id,
      onToggle: () => r.setOpen(r.open === i.id ? null : i.id),
      onRemove: () => r.setItems(r.items.filter(x => x.id !== i.id))
    }))), /*#__PURE__*/React.createElement("div", {
      className: "btn-row",
      style: {
        marginTop: 4
      }
    }, /*#__PURE__*/React.createElement(Button, {
      size: "sm",
      variant: "secondary",
      icon: "plus"
    }, "Add missing item"), /*#__PURE__*/React.createElement(Button, {
      size: "sm",
      variant: "secondary",
      icon: "chat-text"
    }, "Refine with text")));
  }
  function ReviewExtras({
    r
  }) {
    const on = r.extras.filter(e => e.on);
    const kcal = on.reduce((a, e) => a + e.kcal, 0);
    return /*#__PURE__*/React.createElement(Card, {
      padding: "none"
    }, /*#__PURE__*/React.createElement("button", {
      type: "button",
      className: "drawer__head",
      "aria-expanded": r.drawer,
      onClick: () => r.setDrawer(!r.drawer)
    }, /*#__PURE__*/React.createElement("b", null, "Sauces, oils & seasonings"), /*#__PURE__*/React.createElement("span", null, on.length, " \xB7 +", kcal), /*#__PURE__*/React.createElement(Icon, {
      name: r.drawer ? 'caret-up' : 'caret-down',
      size: 14,
      weight: "bold",
      color: "var(--text-tertiary)"
    })), r.drawer ? /*#__PURE__*/React.createElement("div", {
      className: "drawer__body"
    }, r.extras.map(e => /*#__PURE__*/React.createElement(Checkbox, {
      key: e.id,
      checked: e.on,
      dimUnchecked: true,
      label: e.name,
      description: e.serving,
      trailing: '+' + e.kcal,
      onChange: v => r.setExtras(r.extras.map(x => x.id === e.id ? {
        ...x,
        on: v
      } : x))
    }))) : null);
  }
  function ReviewSave({
    r,
    onSave
  }) {
    return /*#__PURE__*/React.createElement(Button, {
      variant: "accent",
      size: "lg",
      fullWidth: true,
      onClick: () => onSave && onSave(r.meal())
    }, "Save ", /*#__PURE__*/React.createElement("span", {
      className: "nn-num"
    }, r.totals.kcal), " kcal to diary");
  }
  function ReviewScreen({
    onClose,
    onRetake,
    onSave
  }) {
    const r = useReview();
    return /*#__PURE__*/React.createElement("div", {
      className: "scr"
    }, /*#__PURE__*/React.createElement("div", {
      className: "scr__top"
    }, /*#__PURE__*/React.createElement(NavBar, {
      title: "Review",
      leading: /*#__PURE__*/React.createElement(IconButton, {
        icon: "x",
        label: "Discard",
        variant: "filled",
        size: 36,
        onClick: onClose
      }),
      trailing: /*#__PURE__*/React.createElement(Button, {
        size: "sm",
        variant: "ghost",
        onClick: onRetake
      }, "Retake")
    })), /*#__PURE__*/React.createElement("div", {
      className: "scr__scroll"
    }, /*#__PURE__*/React.createElement(MealPhoto, {
      label: "captured photo",
      radius: 28,
      style: {
        width: '100%',
        height: 150
      }
    }), /*#__PURE__*/React.createElement(ReviewHeader, {
      r: r
    }), /*#__PURE__*/React.createElement(ReviewItems, {
      r: r
    }), /*#__PURE__*/React.createElement(ReviewExtras, {
      r: r
    })), /*#__PURE__*/React.createElement("div", {
      className: "scr__footer"
    }, /*#__PURE__*/React.createElement(ReviewSave, {
      r: r,
      onSave: onSave
    })));
  }
  Object.assign(window, {
    useReview,
    ReviewHeader,
    ReviewItems,
    ReviewExtras,
    ReviewSave,
    ReviewScreen
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios/ReviewScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/ios/ServingSheet.jsx
try { (() => {
(function () {
  const {
    Sheet,
    Button,
    Chip,
    Stepper,
    Badge,
    MacroLine
  } = window.NomnomDesignSystem_ec1f66;

  // Product match (barcode) and default serving calculator (manual) share this sheet.
  function ServingSheet({
    open,
    food,
    method = 'manual',
    onClose,
    onAdd
  }) {
    const [unit, setUnit] = React.useState(0);
    const [qty, setQty] = React.useState(1);
    React.useEffect(() => {
      setUnit(0);
      setQty(1);
    }, [food]);
    if (!food) return /*#__PURE__*/React.createElement(Sheet, {
      open: false
    });
    const s = food.servings[unit] || food.servings[0];
    const v = k => food.per100[k] * s.g * qty / 100;
    const add = () => onAdd && onAdd({
      title: food.name,
      kcal: v('kcal'),
      protein: v('p'),
      carbs: v('c'),
      fat: v('f'),
      method,
      items: [{
        name: food.name,
        serving: qty + ' × ' + s.label,
        kcal: Math.round(v('kcal'))
      }]
    });
    return /*#__PURE__*/React.createElement(Sheet, {
      open: open,
      onClose: onClose,
      title: food.name,
      footer: /*#__PURE__*/React.createElement(Button, {
        variant: "accent",
        size: "lg",
        fullWidth: true,
        onClick: add
      }, "Add ", /*#__PURE__*/React.createElement("span", {
        className: "nn-num"
      }, Math.round(v('kcal'))), " kcal to diary")
    }, /*#__PURE__*/React.createElement("div", {
      className: "serv"
    }, /*#__PURE__*/React.createElement("div", {
      className: "serv__meta"
    }, food.brand, /*#__PURE__*/React.createElement(Badge, {
      tone: "info"
    }, food.source)), /*#__PURE__*/React.createElement("div", {
      className: "btn-row"
    }, food.servings.map((o, i) => /*#__PURE__*/React.createElement(Chip, {
      key: o.label,
      selected: i === unit,
      onClick: () => setUnit(i)
    }, o.label, /^\d+g$/.test(o.label) ? null : /*#__PURE__*/React.createElement("i", null, o.g, "g")))), /*#__PURE__*/React.createElement("div", {
      className: "serv__qty"
    }, /*#__PURE__*/React.createElement("span", null, "Quantity"), /*#__PURE__*/React.createElement(Stepper, {
      value: qty,
      onChange: setQty,
      min: 0.5
    })), /*#__PURE__*/React.createElement("div", {
      className: "serv__totals"
    }, /*#__PURE__*/React.createElement("span", {
      className: "kcal-lg"
    }, Math.round(v('kcal')), /*#__PURE__*/React.createElement("small", null, "kcal")), /*#__PURE__*/React.createElement(MacroLine, {
      size: "md",
      protein: v('p'),
      carbs: v('c'),
      fat: v('f')
    }))));
  }
  Object.assign(window, {
    ServingSheet
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios/ServingSheet.jsx", error: String((e && e.message) || e) }); }

// ui_kits/ios/SettingsScreen.jsx
try { (() => {
(function () {
  const {
    NavBar,
    IconButton,
    Button,
    Card,
    ListRow,
    Switch,
    Dialog
  } = window.NomnomDesignSystem_ec1f66;
  function SettingsScreen({
    onBack,
    onImport,
    onSignOut
  }) {
    const [camera, setCamera] = React.useState(false);
    const [health, setHealth] = React.useState(true);
    const [syncing, setSyncing] = React.useState(false);
    const [ask, setAsk] = React.useState(false);
    const syncNow = () => {
      setSyncing(true);
      setTimeout(() => setSyncing(false), 1400);
    };
    return /*#__PURE__*/React.createElement("div", {
      className: "scr"
    }, /*#__PURE__*/React.createElement("div", {
      className: "scr__top"
    }, /*#__PURE__*/React.createElement(NavBar, {
      largeTitle: "Settings",
      leading: /*#__PURE__*/React.createElement(IconButton, {
        icon: "caret-left",
        label: "Back",
        variant: "filled",
        size: 36,
        weight: "bold",
        iconSize: 16,
        onClick: onBack
      })
    })), /*#__PURE__*/React.createElement("div", {
      className: "scr__scroll"
    }, /*#__PURE__*/React.createElement(Card, {
      padding: "md",
      className: "account"
    }, /*#__PURE__*/React.createElement("span", {
      className: "account__avatar"
    }, "b"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("b", null, "Brian"), /*#__PURE__*/React.createElement("span", null, "Signed in with Apple \xB7 Hide My Email"))), /*#__PURE__*/React.createElement("div", {
      className: "sec"
    }, /*#__PURE__*/React.createElement("div", {
      className: "sec__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, "Sync"), /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, "Last synced 9:41")), /*#__PURE__*/React.createElement(Card, {
      padding: "none"
    }, /*#__PURE__*/React.createElement(ListRow, {
      icon: "device-mobile",
      title: "iPhone",
      subtitle: "This device",
      value: "Just now"
    }), /*#__PURE__*/React.createElement(ListRow, {
      icon: "book-open",
      title: "iPhone Duo",
      value: "2 h ago"
    }), /*#__PURE__*/React.createElement(ListRow, {
      icon: "device-tablet",
      title: "iPad",
      value: "Yesterday"
    })), /*#__PURE__*/React.createElement(Button, {
      variant: "secondary",
      icon: "arrows-clockwise",
      loading: syncing,
      onClick: syncNow
    }, syncing ? 'Syncing' : 'Sync now')), /*#__PURE__*/React.createElement("div", {
      className: "sec"
    }, /*#__PURE__*/React.createElement("div", {
      className: "sec__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, "Capture")), /*#__PURE__*/React.createElement(Card, {
      padding: "none"
    }, /*#__PURE__*/React.createElement(ListRow, {
      icon: "camera",
      title: "Open to camera",
      subtitle: "Skip Today and start on the viewfinder",
      trailing: /*#__PURE__*/React.createElement(Switch, {
        checked: camera,
        onChange: setCamera,
        label: "Open to camera"
      })
    }))), /*#__PURE__*/React.createElement("div", {
      className: "sec"
    }, /*#__PURE__*/React.createElement("div", {
      className: "sec__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, "Integrations")), /*#__PURE__*/React.createElement(Card, {
      padding: "none"
    }, /*#__PURE__*/React.createElement(ListRow, {
      icon: "heartbeat",
      title: "Apple Health",
      subtitle: "Write meals to Health",
      trailing: /*#__PURE__*/React.createElement(Switch, {
        checked: health,
        onChange: setHealth,
        label: "Apple Health"
      })
    }), /*#__PURE__*/React.createElement(ListRow, {
      icon: "markdown-logo",
      title: "Obsidian daily notes",
      value: "Off",
      chevron: true,
      onClick: () => {}
    }))), /*#__PURE__*/React.createElement("div", {
      className: "sec"
    }, /*#__PURE__*/React.createElement("div", {
      className: "sec__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, "Your data")), /*#__PURE__*/React.createElement(Card, {
      padding: "none"
    }, /*#__PURE__*/React.createElement(ListRow, {
      icon: "download-simple",
      title: "Import history",
      subtitle: "MyFitnessPal or Apple Health",
      chevron: true,
      onClick: onImport
    }), /*#__PURE__*/React.createElement(ListRow, {
      icon: "export",
      title: "Export archive",
      subtitle: "JSON, CSV and photos",
      value: ".zip",
      chevron: true,
      onClick: () => {}
    }))), /*#__PURE__*/React.createElement(Card, {
      padding: "none"
    }, /*#__PURE__*/React.createElement(ListRow, {
      icon: "sign-out",
      title: "Sign out",
      onClick: onSignOut
    }), /*#__PURE__*/React.createElement(ListRow, {
      icon: "trash",
      title: "Delete account",
      tone: "destructive",
      onClick: () => setAsk(true)
    })), /*#__PURE__*/React.createElement("p", {
      className: "fine"
    }, "nomnom 0.1 \xB7 No ads, no trackers")), /*#__PURE__*/React.createElement(Dialog, {
      open: ask,
      onClose: () => setAsk(false),
      title: "Delete your account?",
      actions: [{
        label: 'Delete account',
        variant: 'destructive',
        onClick: onSignOut
      }, {
        label: 'Keep account',
        onClick: () => setAsk(false)
      }]
    }, "This permanently deletes your diary, photos and synced data on every device, and revokes Sign in with Apple. Export an archive first if you want a copy."));
  }
  Object.assign(window, {
    SettingsScreen
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios/SettingsScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/ios/SignInScreen.jsx
try { (() => {
(function () {
  const {
    Button,
    Icon,
    MealPhoto
  } = window.NomnomDesignSystem_ec1f66;
  function SignInScreen({
    onSignIn,
    onImport,
    split
  }) {
    const visual = /*#__PURE__*/React.createElement(MealPhoto, {
      label: "product visual",
      radius: 36,
      style: {
        width: '100%',
        height: '100%'
      }
    });
    const copy = /*#__PURE__*/React.createElement("div", {
      className: "signin__body"
    }, /*#__PURE__*/React.createElement("h1", {
      className: "signin__hero"
    }, "A food diary you can ", /*#__PURE__*/React.createElement("i", null, "keep up with.")), /*#__PURE__*/React.createElement("ul", {
      className: "signin__points"
    }, /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement(Icon, {
      name: "camera",
      size: 20
    }), "Snap a plate. Calories and macros in a few seconds."), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement(Icon, {
      name: "cloud-check",
      size: 20
    }), "Works offline and syncs across your devices."), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement(Icon, {
      name: "export",
      size: 20
    }), "Your data stays yours. Export it any time.")));
    const actions = /*#__PURE__*/React.createElement("div", {
      className: "signin__actions"
    }, /*#__PURE__*/React.createElement(Button, {
      size: "lg",
      fullWidth: true,
      icon: "apple-logo",
      iconWeight: "fill",
      onClick: onSignIn
    }, "Sign in with Apple"), /*#__PURE__*/React.createElement("button", {
      type: "button",
      className: "signin__import",
      onClick: onImport
    }, "Already tracking in MyFitnessPal? ", /*#__PURE__*/React.createElement("u", null, "Import your history")), /*#__PURE__*/React.createElement("p", {
      className: "signin__fine"
    }, "No ads. No streaks. Delete your account any time."));
    if (split === 'left') return /*#__PURE__*/React.createElement("div", {
      className: "scr"
    }, /*#__PURE__*/React.createElement("div", {
      className: "scr__top"
    }, /*#__PURE__*/React.createElement("div", {
      className: "signin__mark"
    }, /*#__PURE__*/React.createElement("img", {
      src: "../../assets/app-icon.svg",
      alt: ""
    }), "nomnom")), /*#__PURE__*/React.createElement("div", {
      className: "signin__visual",
      style: {
        paddingBottom: 20
      }
    }, visual));
    if (split === 'right') return /*#__PURE__*/React.createElement("div", {
      className: "scr"
    }, /*#__PURE__*/React.createElement("div", {
      className: "scr__top"
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }), copy, actions);
    return /*#__PURE__*/React.createElement("div", {
      className: "scr"
    }, /*#__PURE__*/React.createElement("div", {
      className: "scr__top"
    }, /*#__PURE__*/React.createElement("div", {
      className: "signin__mark"
    }, /*#__PURE__*/React.createElement("img", {
      src: "../../assets/app-icon.svg",
      alt: ""
    }), "nomnom")), /*#__PURE__*/React.createElement("div", {
      className: "signin__visual"
    }, visual), copy, actions);
  }
  Object.assign(window, {
    SignInScreen
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios/SignInScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/ios/TodayScreen.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
(function () {
  const {
    NavBar,
    SyncPill,
    IconButton,
    DailySummary,
    MealRow,
    Card,
    CaptureDock,
    Button
  } = window.NomnomDesignSystem_ec1f66;
  function TodayScreen({
    meals = [],
    sync = 'synced',
    queued,
    selectedId,
    compactSummary,
    compactDock,
    onSnap,
    onBarcode,
    onManual,
    onMeal,
    onSettings,
    onImport
  }) {
    const D = window.NN_DATA;
    const sum = k => meals.reduce((a, m) => a + (m.pending ? 0 : m[k] || 0), 0);
    return /*#__PURE__*/React.createElement("div", {
      className: "scr"
    }, /*#__PURE__*/React.createElement("div", {
      className: "scr__top"
    }, /*#__PURE__*/React.createElement(NavBar, {
      largeTitle: "Today",
      subtitle: compactSummary ? null : D.today,
      leading: /*#__PURE__*/React.createElement(SyncPill, {
        status: sync,
        queued: queued
      }),
      trailing: /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(IconButton, {
        icon: "calendar-blank",
        label: "Pick a date",
        variant: "filled",
        size: 36
      }), /*#__PURE__*/React.createElement(IconButton, {
        icon: "gear-six",
        label: "Settings",
        variant: "filled",
        size: 36,
        onClick: onSettings
      }))
    })), /*#__PURE__*/React.createElement("div", {
      className: "scr__scroll",
      style: {
        paddingBottom: compactDock ? 104 : 130
      }
    }, /*#__PURE__*/React.createElement(DailySummary, {
      compact: compactSummary,
      kcal: sum('kcal'),
      target: D.targets.kcal,
      protein: {
        value: sum('protein'),
        target: D.targets.protein
      },
      carbs: {
        value: sum('carbs'),
        target: D.targets.carbs
      },
      fat: {
        value: sum('fat'),
        target: D.targets.fat
      },
      micros: meals.length ? D.micros : []
    }), /*#__PURE__*/React.createElement("div", {
      className: "sec"
    }, /*#__PURE__*/React.createElement("div", {
      className: "sec__head"
    }, /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, "Meals"), meals.length ? /*#__PURE__*/React.createElement("span", {
      className: "nn-overline"
    }, meals.length, " logged") : null), meals.length ? /*#__PURE__*/React.createElement(Card, {
      padding: "none",
      style: {
        padding: 8
      }
    }, meals.map(m => /*#__PURE__*/React.createElement(MealRow, _extends({
      key: m.id
    }, m, {
      selected: m.id === selectedId,
      onClick: () => onMeal && onMeal(m)
    })))) : /*#__PURE__*/React.createElement(Card, {
      tone: "outline",
      className: "empty"
    }, /*#__PURE__*/React.createElement("h2", null, "Nothing logged yet"), /*#__PURE__*/React.createElement("p", null, "Snap your first plate with the camera button below, or bring your history over from MyFitnessPal."), /*#__PURE__*/React.createElement(Button, {
      size: "sm",
      variant: "secondary",
      icon: "download-simple",
      onClick: onImport
    }, "Import history")))), /*#__PURE__*/React.createElement("div", {
      className: "scr__dock"
    }, /*#__PURE__*/React.createElement(CaptureDock, {
      compact: compactDock,
      onSnap: onSnap,
      onBarcode: onBarcode,
      onManual: onManual
    })));
  }
  Object.assign(window, {
    TodayScreen
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios/TodayScreen.jsx", error: String((e && e.message) || e) }); }

// ui_kits/ios/data.js
try { (() => {
// Sample content for the nomnom UI kits. All values are illustrative.
window.NN_DATA = {
  today: 'Friday, 27 November',
  targets: {
    kcal: 2100,
    protein: 120,
    carbs: 240,
    fat: 70
  },
  micros: [{
    label: 'Fiber',
    value: '14 g'
  }, {
    label: 'Sugar',
    value: '31 g'
  }, {
    label: 'Sodium',
    value: '1,280 mg'
  }, {
    label: 'Sat. fat',
    value: '11 g'
  }, {
    label: 'Potassium',
    value: '1,950 mg'
  }, {
    label: 'Iron',
    value: '9 mg'
  }],
  meals: [{
    id: 'm3',
    title: 'Salmon rice bowl',
    mealType: 'Lunch',
    time: '12:40',
    kcal: 642,
    protein: 38,
    carbs: 58,
    fat: 27,
    method: 'photo_ai',
    items: [{
      name: 'Salmon fillet',
      serving: '1 fillet (~150g)',
      kcal: 280
    }, {
      name: 'Sushi rice',
      serving: '1 cup (~160g)',
      kcal: 210
    }, {
      name: 'Avocado',
      serving: '¼ (~35g)',
      kcal: 56
    }, {
      name: 'Edamame',
      serving: '¼ cup',
      kcal: 47
    }, {
      name: 'Sesame oil',
      serving: '1 tsp',
      kcal: 40
    }, {
      name: 'Soy sauce',
      serving: '1 tbsp',
      kcal: 9
    }]
  }, {
    id: 'm2',
    title: 'Flat white',
    mealType: 'Snack',
    time: '10:10',
    kcal: 120,
    protein: 6,
    carbs: 9,
    fat: 6,
    method: 'barcode',
    items: [{
      name: 'Flat white, whole milk',
      serving: '8 fl oz',
      kcal: 120
    }]
  }, {
    id: 'm1',
    title: 'Overnight oats with berries',
    mealType: 'Breakfast',
    time: '7:45',
    kcal: 363,
    protein: 14,
    carbs: 55,
    fat: 10,
    method: 'manual',
    items: [{
      name: 'Rolled oats',
      serving: '½ cup (40g)',
      kcal: 150
    }, {
      name: 'Milk, 2%',
      serving: '¾ cup',
      kcal: 92
    }, {
      name: 'Chia seeds',
      serving: '1 tbsp',
      kcal: 58
    }, {
      name: 'Mixed berries',
      serving: '½ cup',
      kcal: 42
    }, {
      name: 'Honey',
      serving: '1 tsp',
      kcal: 21
    }]
  }],
  detectedTitle: 'Chicken thigh plate',
  detected: [{
    id: 'd1',
    name: 'Chicken thigh, grilled',
    serving: '2 thighs (~180g)',
    kcal: 330,
    p: 38,
    c: 0,
    f: 19,
    confidence: 0.92
  }, {
    id: 'd2',
    name: 'Jasmine rice',
    serving: '1 cup (~160g)',
    kcal: 205,
    p: 4,
    c: 45,
    f: 0,
    confidence: 0.88
  }, {
    id: 'd3',
    name: 'Broccolini',
    serving: '1 cup (~90g)',
    kcal: 40,
    p: 3,
    c: 6,
    f: 1,
    confidence: 0.71
  }],
  extras: [{
    id: 'e1',
    name: 'Olive oil',
    serving: '2 tsp',
    kcal: 80,
    p: 0,
    c: 0,
    f: 9,
    on: true
  }, {
    id: 'e2',
    name: 'Soy glaze',
    serving: '1 tbsp',
    kcal: 25,
    p: 1,
    c: 5,
    f: 0,
    on: true
  }, {
    id: 'e3',
    name: 'Sesame seeds',
    serving: '1 tsp',
    kcal: 17,
    p: 1,
    c: 1,
    f: 1,
    on: true
  }],
  recents: [{
    name: 'Greek yogurt, plain',
    brand: '2% fat',
    source: 'USDA',
    per100: {
      kcal: 73,
      p: 9.9,
      c: 3.9,
      f: 2
    },
    servings: [{
      label: '1 cup',
      g: 170
    }, {
      label: '100g',
      g: 100
    }, {
      label: '1 tub',
      g: 500
    }]
  }, {
    name: 'Scrambled eggs',
    brand: 'Cooked in butter',
    source: 'USDA',
    per100: {
      kcal: 148,
      p: 10,
      c: 1.6,
      f: 11
    },
    servings: [{
      label: '2 eggs',
      g: 122
    }, {
      label: '1 egg',
      g: 61
    }, {
      label: '100g',
      g: 100
    }]
  }, {
    name: 'Sourdough toast',
    brand: 'Bakery',
    source: 'USDA',
    per100: {
      kcal: 272,
      p: 9,
      c: 52,
      f: 2
    },
    servings: [{
      label: '1 slice',
      g: 50
    }, {
      label: '100g',
      g: 100
    }]
  }, {
    name: 'Banana',
    brand: 'Raw',
    source: 'USDA',
    per100: {
      kcal: 89,
      p: 1.1,
      c: 22.8,
      f: 0.3
    },
    servings: [{
      label: '1 medium',
      g: 118
    }, {
      label: '100g',
      g: 100
    }]
  }, {
    name: 'Almonds',
    brand: 'Dry roasted',
    source: 'USDA',
    per100: {
      kcal: 579,
      p: 21,
      c: 22,
      f: 50
    },
    servings: [{
      label: '1 handful',
      g: 28
    }, {
      label: '100g',
      g: 100
    }]
  }],
  product: {
    name: 'Dark chocolate almond bar',
    brand: 'Good Grain Co.',
    source: 'Open Food Facts',
    per100: {
      kcal: 500,
      p: 15,
      c: 40,
      f: 35
    },
    servings: [{
      label: '1 bar',
      g: 40
    }, {
      label: '100g',
      g: 100
    }]
  },
  week: {
    range: '21 – 27 November',
    days: ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    kcal: [1840, 2050, 1920, 2210, 1760, 2080, 1125],
    avg: {
      protein: 104,
      carbs: 212,
      fat: 66
    }
  },
  importRows: [['24 Nov', 'Breakfast', 412, 22, 48, 14], ['24 Nov', 'Lunch', 688, 41, 62, 28], ['24 Nov', 'Dinner', 734, 46, 70, 27], ['24 Nov', 'Snacks', 190, 6, 24, 8]]
};
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios/data.js", error: String((e && e.message) || e) }); }

// ui_kits/ios/ios-frame.jsx
try { (() => {
// @ds-adherence-ignore -- omelette starter scaffold (raw elements/hex/px by design)
// Copied omelette starter. Re-running copy_starter_component with this kind overwrites this file with the latest version (page content is unaffected).

/* BEGIN USAGE */
// iOS.jsx — Simplified iOS 26 (Liquid Glass) device frame
// Based on the iOS 26 UI Kit + Figma status bar spec. No assets, no deps.
// Exports (to window): IOSDevice, IOSStatusBar, IOSNavBar, IOSGlassPill, IOSList, IOSListRow, IOSKeyboard
//
// Usage — wrap your screen content in <IOSDevice> to get the bezel, status bar
// and home indicator (props: title, dark, keyboard):
//
//   <IOSDevice title="Settings">
//     ...your screen content...
//   </IOSDevice>
//   <IOSDevice dark title="Search" keyboard>…</IOSDevice>
/* END USAGE */

// ─────────────────────────────────────────────────────────────
// Status bar
// ─────────────────────────────────────────────────────────────
function IOSStatusBar({
  dark = false,
  time = '9:41'
}) {
  const c = dark ? '#fff' : '#000';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 154,
      alignItems: 'center',
      justifyContent: 'center',
      padding: '21px 24px 19px',
      boxSizing: 'border-box',
      position: 'relative',
      zIndex: 20,
      width: '100%'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      paddingTop: 1.5
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: '-apple-system, "SF Pro", system-ui',
      fontWeight: 590,
      fontSize: 17,
      lineHeight: '22px',
      color: c
    }
  }, time)), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      height: 22,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      gap: 7,
      paddingTop: 1,
      paddingRight: 1
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "19",
    height: "12",
    viewBox: "0 0 19 12"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0",
    y: "7.5",
    width: "3.2",
    height: "4.5",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "4.8",
    y: "5",
    width: "3.2",
    height: "7",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "9.6",
    y: "2.5",
    width: "3.2",
    height: "9.5",
    rx: "0.7",
    fill: c
  }), /*#__PURE__*/React.createElement("rect", {
    x: "14.4",
    y: "0",
    width: "3.2",
    height: "12",
    rx: "0.7",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "17",
    height: "12",
    viewBox: "0 0 17 12"
  }, /*#__PURE__*/React.createElement("path", {
    d: "M8.5 3.2C10.8 3.2 12.9 4.1 14.4 5.6L15.5 4.5C13.7 2.7 11.2 1.5 8.5 1.5C5.8 1.5 3.3 2.7 1.5 4.5L2.6 5.6C4.1 4.1 6.2 3.2 8.5 3.2Z",
    fill: c
  }), /*#__PURE__*/React.createElement("path", {
    d: "M8.5 6.8C9.9 6.8 11.1 7.3 12 8.2L13.1 7.1C11.8 5.9 10.2 5.1 8.5 5.1C6.8 5.1 5.2 5.9 3.9 7.1L5 8.2C5.9 7.3 7.1 6.8 8.5 6.8Z",
    fill: c
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "8.5",
    cy: "10.5",
    r: "1.5",
    fill: c
  })), /*#__PURE__*/React.createElement("svg", {
    width: "27",
    height: "13",
    viewBox: "0 0 27 13"
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0.5",
    y: "0.5",
    width: "23",
    height: "12",
    rx: "3.5",
    stroke: c,
    strokeOpacity: "0.35",
    fill: "none"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "2",
    y: "2",
    width: "20",
    height: "9",
    rx: "2",
    fill: c
  }), /*#__PURE__*/React.createElement("path", {
    d: "M25 4.5V8.5C25.8 8.2 26.5 7.2 26.5 6.5C26.5 5.8 25.8 4.8 25 4.5Z",
    fill: c,
    fillOpacity: "0.4"
  }))));
}

// ─────────────────────────────────────────────────────────────
// Liquid glass pill — blur + tint + shine
// ─────────────────────────────────────────────────────────────
function IOSGlassPill({
  children,
  dark = false,
  style = {}
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 44,
      minWidth: 44,
      borderRadius: 9999,
      position: 'relative',
      overflow: 'hidden',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      boxShadow: dark ? '0 2px 6px rgba(0,0,0,0.35), 0 6px 16px rgba(0,0,0,0.2)' : '0 1px 3px rgba(0,0,0,0.07), 0 3px 10px rgba(0,0,0,0.06)',
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 9999,
      backdropFilter: 'blur(12px) saturate(180%)',
      WebkitBackdropFilter: 'blur(12px) saturate(180%)',
      background: dark ? 'rgba(120,120,128,0.28)' : 'rgba(255,255,255,0.5)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 9999,
      boxShadow: dark ? 'inset 1.5px 1.5px 1px rgba(255,255,255,0.15), inset -1px -1px 1px rgba(255,255,255,0.08)' : 'inset 1.5px 1.5px 1px rgba(255,255,255,0.7), inset -1px -1px 1px rgba(255,255,255,0.4)',
      border: dark ? '0.5px solid rgba(255,255,255,0.15)' : '0.5px solid rgba(0,0,0,0.06)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 1,
      display: 'flex',
      alignItems: 'center',
      padding: '0 4px'
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Navigation bar — glass pills + large title
// ─────────────────────────────────────────────────────────────
function IOSNavBar({
  title = 'Title',
  dark = false,
  trailingIcon = true
}) {
  const muted = dark ? 'rgba(255,255,255,0.6)' : '#404040';
  const text = dark ? '#fff' : '#000';
  const pillIcon = content => /*#__PURE__*/React.createElement(IOSGlassPill, {
    dark: dark
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center'
    }
  }, content));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 10,
      paddingTop: 62,
      paddingBottom: 10,
      position: 'relative',
      zIndex: 5
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      padding: '0 16px'
    }
  }, pillIcon(/*#__PURE__*/React.createElement("svg", {
    width: "12",
    height: "20",
    viewBox: "0 0 12 20",
    fill: "none",
    style: {
      marginLeft: -1
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M10 2L2 10l8 8",
    stroke: muted,
    strokeWidth: "2.5",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  }))), trailingIcon && pillIcon(/*#__PURE__*/React.createElement("svg", {
    width: "22",
    height: "6",
    viewBox: "0 0 22 6"
  }, /*#__PURE__*/React.createElement("circle", {
    cx: "3",
    cy: "3",
    r: "2.5",
    fill: muted
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "11",
    cy: "3",
    r: "2.5",
    fill: muted
  }), /*#__PURE__*/React.createElement("circle", {
    cx: "19",
    cy: "3",
    r: "2.5",
    fill: muted
  })))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: '0 16px',
      fontFamily: '-apple-system, system-ui',
      fontSize: 34,
      fontWeight: 700,
      lineHeight: '41px',
      color: text,
      letterSpacing: 0.4
    }
  }, title));
}

// ─────────────────────────────────────────────────────────────
// Grouped list (inset card, r:26) + row (52px)
// ─────────────────────────────────────────────────────────────
function IOSListRow({
  title,
  detail,
  icon,
  chevron = true,
  isLast = false,
  dark = false
}) {
  const text = dark ? '#fff' : '#000';
  const sec = dark ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)';
  const ter = dark ? 'rgba(235,235,245,0.3)' : 'rgba(60,60,67,0.3)';
  const sep = dark ? 'rgba(84,84,88,0.65)' : 'rgba(60,60,67,0.12)';
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      alignItems: 'center',
      minHeight: 52,
      padding: '0 16px',
      position: 'relative',
      fontFamily: '-apple-system, system-ui',
      fontSize: 17,
      letterSpacing: -0.43
    }
  }, icon && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 30,
      height: 30,
      borderRadius: 7,
      background: icon,
      marginRight: 12,
      flexShrink: 0
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      color: text
    }
  }, title), detail && /*#__PURE__*/React.createElement("span", {
    style: {
      color: sec,
      marginRight: 6
    }
  }, detail), chevron && /*#__PURE__*/React.createElement("svg", {
    width: "8",
    height: "14",
    viewBox: "0 0 8 14",
    style: {
      flexShrink: 0
    }
  }, /*#__PURE__*/React.createElement("path", {
    d: "M1 1l6 6-6 6",
    stroke: ter,
    strokeWidth: "2",
    fill: "none",
    strokeLinecap: "round",
    strokeLinejoin: "round"
  })), !isLast && /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      bottom: 0,
      right: 0,
      left: icon ? 58 : 16,
      height: 0.5,
      background: sep
    }
  }));
}
function IOSList({
  header,
  children,
  dark = false
}) {
  const hc = dark ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)';
  const bg = dark ? '#1C1C1E' : '#fff';
  return /*#__PURE__*/React.createElement("div", null, header && /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: '-apple-system, system-ui',
      fontSize: 13,
      color: hc,
      textTransform: 'uppercase',
      padding: '8px 36px 6px',
      letterSpacing: -0.08
    }
  }, header), /*#__PURE__*/React.createElement("div", {
    style: {
      background: bg,
      borderRadius: 26,
      margin: '0 16px',
      overflow: 'hidden'
    }
  }, children));
}

// ─────────────────────────────────────────────────────────────
// Device frame
// ─────────────────────────────────────────────────────────────
function IOSDevice({
  children,
  width = 402,
  height = 874,
  dark = false,
  title,
  keyboard = false
}) {
  return (
    /*#__PURE__*/
    // data-om-starter: inert presence marker — Claude Design's starter-usage
    // probe reads it; it renders nothing. Keep it on this root element.
    React.createElement("div", {
      "data-om-starter": "ios-frame",
      style: {
        width,
        height,
        borderRadius: 48,
        overflow: 'hidden',
        position: 'relative',
        background: dark ? '#000' : '#F2F2F7',
        boxShadow: '0 40px 80px rgba(0,0,0,0.18), 0 0 0 1px rgba(0,0,0,0.12)',
        fontFamily: '-apple-system, system-ui, sans-serif',
        WebkitFontSmoothing: 'antialiased'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        top: 11,
        left: '50%',
        transform: 'translateX(-50%)',
        width: 126,
        height: 37,
        borderRadius: 24,
        background: '#000',
        zIndex: 50
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        zIndex: 10
      }
    }, /*#__PURE__*/React.createElement(IOSStatusBar, {
      dark: dark
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        height: '100%',
        display: 'flex',
        flexDirection: 'column'
      }
    }, title !== undefined && /*#__PURE__*/React.createElement(IOSNavBar, {
      title: title,
      dark: dark
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        overflow: 'auto'
      }
    }, children), keyboard && /*#__PURE__*/React.createElement(IOSKeyboard, {
      dark: dark
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        zIndex: 60,
        height: 34,
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'flex-end',
        paddingBottom: 8,
        pointerEvents: 'none'
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 139,
        height: 5,
        borderRadius: 100,
        background: dark ? 'rgba(255,255,255,0.7)' : 'rgba(0,0,0,0.25)'
      }
    })))
  );
}

// ─────────────────────────────────────────────────────────────
// Keyboard — iOS 26 liquid glass
// ─────────────────────────────────────────────────────────────
function IOSKeyboard({
  dark = false
}) {
  const glyph = dark ? 'rgba(255,255,255,0.7)' : '#595959';
  const sugg = dark ? 'rgba(255,255,255,0.6)' : '#333';
  const keyBg = dark ? 'rgba(255,255,255,0.22)' : 'rgba(255,255,255,0.85)';

  // special-key icons
  const icons = {
    shift: /*#__PURE__*/React.createElement("svg", {
      width: "19",
      height: "17",
      viewBox: "0 0 19 17"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M9.5 1L1 9.5h4.5V16h8V9.5H18L9.5 1z",
      fill: glyph
    })),
    del: /*#__PURE__*/React.createElement("svg", {
      width: "23",
      height: "17",
      viewBox: "0 0 23 17"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M7 1h13a2 2 0 012 2v11a2 2 0 01-2 2H7l-6-7.5L7 1z",
      fill: "none",
      stroke: glyph,
      strokeWidth: "1.6",
      strokeLinejoin: "round"
    }), /*#__PURE__*/React.createElement("path", {
      d: "M10 5l7 7M17 5l-7 7",
      stroke: glyph,
      strokeWidth: "1.6",
      strokeLinecap: "round"
    })),
    ret: /*#__PURE__*/React.createElement("svg", {
      width: "20",
      height: "14",
      viewBox: "0 0 20 14"
    }, /*#__PURE__*/React.createElement("path", {
      d: "M18 1v6H4m0 0l4-4M4 7l4 4",
      fill: "none",
      stroke: "#fff",
      strokeWidth: "1.8",
      strokeLinecap: "round",
      strokeLinejoin: "round"
    }))
  };
  const key = (content, {
    w,
    flex,
    ret,
    fs = 25,
    k
  } = {}) => /*#__PURE__*/React.createElement("div", {
    key: k,
    style: {
      height: 42,
      borderRadius: 8.5,
      flex: flex ? 1 : undefined,
      width: w,
      minWidth: 0,
      background: ret ? '#08f' : keyBg,
      boxShadow: '0 1px 0 rgba(0,0,0,0.075)',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      fontFamily: '-apple-system, "SF Compact", system-ui',
      fontSize: fs,
      fontWeight: 458,
      color: ret ? '#fff' : glyph
    }
  }, content);
  const row = (keys, pad = 0) => /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6.5,
      justifyContent: 'center',
      padding: `0 ${pad}px`
    }
  }, keys.map(l => key(l, {
    flex: true,
    k: l
  })));
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'relative',
      zIndex: 15,
      borderRadius: 27,
      overflow: 'hidden',
      padding: '11px 0 2px',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      boxShadow: dark ? '0 -2px 20px rgba(0,0,0,0.09)' : '0 -1px 6px rgba(0,0,0,0.018), 0 -3px 20px rgba(0,0,0,0.012)'
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 27,
      backdropFilter: 'blur(12px) saturate(180%)',
      WebkitBackdropFilter: 'blur(12px) saturate(180%)',
      background: dark ? 'rgba(120,120,128,0.14)' : 'rgba(255,255,255,0.25)'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: 'absolute',
      inset: 0,
      borderRadius: 27,
      boxShadow: dark ? 'inset 1.5px 1.5px 1px rgba(255,255,255,0.15)' : 'inset 1.5px 1.5px 1px rgba(255,255,255,0.7), inset -1px -1px 1px rgba(255,255,255,0.4)',
      border: dark ? '0.5px solid rgba(255,255,255,0.15)' : '0.5px solid rgba(0,0,0,0.06)',
      pointerEvents: 'none'
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 20,
      alignItems: 'center',
      padding: '8px 22px 13px',
      width: '100%',
      boxSizing: 'border-box',
      position: 'relative'
    }
  }, ['"The"', 'the', 'to'].map((w, i) => /*#__PURE__*/React.createElement(React.Fragment, {
    key: i
  }, i > 0 && /*#__PURE__*/React.createElement("div", {
    style: {
      width: 1,
      height: 25,
      background: '#ccc',
      opacity: 0.3
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      textAlign: 'center',
      fontFamily: '-apple-system, system-ui',
      fontSize: 17,
      color: sugg,
      letterSpacing: -0.43,
      lineHeight: '22px'
    }
  }, w)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      flexDirection: 'column',
      gap: 13,
      padding: '0 6.5px',
      width: '100%',
      boxSizing: 'border-box',
      position: 'relative'
    }
  }, row(['q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p']), row(['a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l'], 20), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 14.25,
      alignItems: 'center'
    }
  }, key(icons.shift, {
    w: 45,
    k: 'shift'
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6.5,
      flex: 1
    }
  }, ['z', 'x', 'c', 'v', 'b', 'n', 'm'].map(l => key(l, {
    flex: true,
    k: l
  }))), key(icons.del, {
    w: 45,
    k: 'del'
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: 'flex',
      gap: 6,
      alignItems: 'center'
    }
  }, key('ABC', {
    w: 92.25,
    fs: 18,
    k: 'abc'
  }), key('', {
    flex: true,
    k: 'space'
  }), key(icons.ret, {
    w: 92.25,
    ret: true,
    k: 'ret'
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      height: 56,
      width: '100%',
      position: 'relative'
    }
  }));
}
Object.assign(window, {
  IOSDevice,
  IOSStatusBar,
  IOSNavBar,
  IOSGlassPill,
  IOSList,
  IOSListRow,
  IOSKeyboard
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/ios/ios-frame.jsx", error: String((e && e.message) || e) }); }

__ds_ns.Badge = __ds_scope.Badge;

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Chip = __ds_scope.Chip;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.IconButton = __ds_scope.IconButton;

__ds_ns.Banner = __ds_scope.Banner;

__ds_ns.Dialog = __ds_scope.Dialog;

__ds_ns.ProgressBar = __ds_scope.ProgressBar;

__ds_ns.Sheet = __ds_scope.Sheet;

__ds_ns.SyncPill = __ds_scope.SyncPill;

__ds_ns.Checkbox = __ds_scope.Checkbox;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Stepper = __ds_scope.Stepper;

__ds_ns.Switch = __ds_scope.Switch;

__ds_ns.TextField = __ds_scope.TextField;

__ds_ns.CaptureDock = __ds_scope.CaptureDock;

__ds_ns.ListRow = __ds_scope.ListRow;

__ds_ns.NavBar = __ds_scope.NavBar;

__ds_ns.DailySummary = __ds_scope.DailySummary;

__ds_ns.FoodItemRow = __ds_scope.FoodItemRow;

__ds_ns.MacroBar = __ds_scope.MacroBar;

__ds_ns.MacroLine = __ds_scope.MacroLine;

__ds_ns.MealPhoto = __ds_scope.MealPhoto;

__ds_ns.MealRow = __ds_scope.MealRow;

})();
