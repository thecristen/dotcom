import { assert } from "chai";
import { iconSvg } from "../../web/static/js/google-map";

describe("google-map", () => {

  describe("iconSvg", () => {
    it("returns correct dot icon", () => {
      const actual = iconSvg('000000-dot');
      const expected = `<svg width="8" height="8" xmlns="http://www.w3.org/2000/svg"><circle fill="#FFFFFF" cx="4" cy="4" r="3"></circle><path d="M4,6.5 C5.38071187,6.5 6.5,5.38071187 6.5,4 C6.5,2.61928813 5.38071187,1.5 4,1.5 C2.61928813,1.5 1.5,2.61928813 1.5,4 C1.5,5.38071187 2.61928813,6.5 4,6.5 Z M4,8 C1.790861,8 0,6.209139 0,4 C0,1.790861 1.790861,0 4,0 C6.209139,0 8,1.790861 8,4 C8,6.209139 6.209139,8 4,8 Z" fill="#000000" fill-rule="nonzero"></path></svg>`
      assert.equal(actual, expected);
    });

    it("returns correct dot-mid icon", () => {
      const actual = iconSvg('000000-dot-mid');
      const expected = `<svg width="16" height="16" xmlns="http://www.w3.org/2000/svg"><circle fill="#FFFFFF" cx="8" cy="8" r="7"></circle><path d="M8,13 C10.7614237,13 13,10.7614237 13,8 C13,5.23857625 10.7614237,3 8,3 C5.23857625,3 3,5.23857625 3,8 C3,10.7614237 5.23857625,13 8,13 Z M8,16 C3.581722,16 0,12.418278 0,8 C0,3.581722 3.581722,0 8,0 C12.418278,0 16,3.581722 16,8 C16,12.418278 12.418278,16 8,16 Z" fill="#000000" fill-rule="nonzero"></path></svg>`
      assert.equal(actual, expected);
    });

    it("returns correct vehicle icon", () => {
      const actual = iconSvg('cr-vehicle');
      const expected = `<svg width="22" height="22" xmlns="http://www.w3.org/2000/svg"><g><circle fill="#FFF" cx="11" cy="11" r="11"></circle><g fill="#1C1E23"><path d="M6.717 9.08a1.028 1.028 0 0 1-.003-.075V7.423c0-.549.427-1.137.951-1.311l2.384-.795c.525-.175 1.378-.175 1.902 0l2.384.795c.525.175.95.754.95 1.311v1.582c0 .026 0 .05-.002.076l.717.205v4c0 .552-.456 1-.995 1h-8.01a.995.995 0 0 1-.995-1v-4l.717-.205zm7.854 3.777a.714.714 0 1 0 0-1.428.714.714 0 0 0 0 1.428zm-7.142 0a.714.714 0 1 0 0-1.428.714.714 0 0 0 0 1.428zm0-5.714V8.57l2.857-.714V6.43l-2.857.714zm4.285-.714v1.428l2.857.714V7.143l-2.857-.714zM6.714 15h8.572v.357a.36.36 0 0 1-.358.357H7.072a.361.361 0 0 1-.358-.357V15zm2.143.714h1.429l-1.429 1.429H7.43l1.428-1.429zm2.857 0h1.429l1.428 1.429h-1.428l-1.429-1.429z"></path></g><path d="M11 19a8 8 0 1 0 0-16 8 8 0 0 0 0 16zm0 3C4.925 22 0 17.075 0 11S4.925 0 11 0s11 4.925 11 11-4.925 11-11 11z" fill="#1C1E23" fill-rule="nonzero"></path></g></svg>`
      assert.equal(actual, expected);
    });

    it("returns undefined for unnexpect input", () => {
      const actual = iconSvg('xxx');
      const expected = undefined
      assert.equal(actual, expected);
    });
  });
});
