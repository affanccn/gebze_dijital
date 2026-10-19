fetch('https://www.gebze.bel.tr/haberler.html')
  .then(r => r.text())
  .then(html => {
    const urls = html.match(/href="([^"]+)"/g)
      .map(s => s.slice(6, -1))
      .filter(u => u.includes('/haber/'));
    console.log(urls.slice(0, 10));
  });
