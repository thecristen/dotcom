const tooltipDivider = "<hr class='tooltip-divider'>";
const vehicleTooltipId = vehicleContainerId => `${vehicleContainerId}-tooltip`;
const escapeSlash = id => id.replace(/\//g, "\\/");

export const addOrUpdateTooltip = (vehicleTooltip, vehicleContainerId) => {
  const containerId = vehicleTooltipId(vehicleContainerId);
  const container = document.getElementById(containerId);
  const currentTooltip = container.getAttribute("data-original-title");
  const stopTooltip = container.getAttribute("data-stop");
  if (stopTooltip) {
    const tooltip = [vehicleTooltip, stopTooltip].join(tooltipDivider);
    // Avoid unnecessary updates
    if (tooltip === currentTooltip) {
      return;
    }
    container.setAttribute("data-original-title", tooltip);
  } else {
    // Avoid unnecessary updates
    if (vehicleTooltip === currentTooltip) {
      return;
    }
    container.setAttribute("data-original-title", vehicleTooltip);
  }
  window.jQuery(escapeSlash(`#${containerId}`)).tooltip("hide");
};

export const removeTooltip = parentId => {
  const tooltipId = `${parentId}-tooltip`;
  const container = document.getElementById(tooltipId);
  const stopTooltip = container.getAttribute("data-stop");
  if (stopTooltip) {
    container.setAttribute("data-original-title", stopTooltip);
  } else {
    container.removeAttribute("data-original-title");
  }
  window.jQuery(`#${escapeSlash(tooltipId)}`).tooltip("hide");
};
