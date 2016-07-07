export default function($) {
    $ = $ || window.jQuery;
    $('.expandable').each((index, el) => {
        const $el = $(el);
        $el.click(() => {
           $el.toggleClass('expanded') ;
        });
    });
};
