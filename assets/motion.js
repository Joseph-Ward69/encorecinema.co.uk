// Fades sections and cards up as they scroll into view. Without this script (or with reduced motion) everything simply shows.
(function () {
  if (!('IntersectionObserver' in window) || matchMedia('(prefers-reduced-motion: reduce)').matches) return;
  document.documentElement.classList.add('js-motion');
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (!e.isIntersecting) return;
      var el = e.target;
      el.classList.add('in');
      io.unobserve(el);
      // Once in place, hand back to the element's own hover effects.
      setTimeout(function () { el.classList.remove('reveal', 'in'); el.style.transitionDelay = ''; }, 1000);
    });
  }, { rootMargin: '0px 0px -8% 0px' });
  var items = document.querySelectorAll('main section > h2, .card, figure.shot:not(.hero-video), .steps li, .callout, .timeline > li, details');
  items.forEach(function (el, i) {
    el.classList.add('reveal');
    el.style.transitionDelay = (i % 3) * 80 + 'ms';
    io.observe(el);
  });
})();
