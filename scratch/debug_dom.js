// Quick script to check what's in the poster card DOM
const puppeteer = require('puppeteer');

(async () => {
    const browser = await puppeteer.launch({ headless: true });
    const page = await browser.newPage();
    await page.goto('http://localhost:8080/', { waitUntil: 'networkidle0' });
    
    // Skip onboarding by setting localStorage
    await page.evaluate(() => {
        localStorage.setItem('schedly_onboarding_done', 'true');
        localStorage.setItem('schedly_history', JSON.stringify([{
            id: 'test1',
            sy: 'S.Y. 2026-2027',
            course: 'BS Information Technology',
            year: '4th Year',
            section: 'A',
            semester: '1st Sem',
            sessions: [
                { id: '1', name: 'The Contemporary World', code: 'GECONTWO', day: 'Monday', start: '01:00 PM', end: '02:30 PM', room: 'Room 101', teacher: 'Prof. X', color: '#8e94f2' },
                { id: '2', name: 'System Admin', code: 'SYSADMLB', day: 'Monday', start: '03:00 PM', end: '06:00 PM', room: 'Room 102', teacher: 'Prof. Y', color: '#e27396' },
                { id: '3', name: 'Info Assurance', code: 'IAASLAB2', day: 'Tuesday', start: '07:00 AM', end: '10:00 AM', room: 'Room 201', teacher: 'Prof. Z', color: '#ffb703' },
            ],
            date: new Date().toISOString()
        }]));
    });
    
    await page.reload({ waitUntil: 'networkidle0' });
    await page.waitForTimeout(1000);
    
    // Navigate to exporter tab
    const tabs = await page.$$('.nav-tab');
    for (const tab of tabs) {
        const text = await page.evaluate(el => el.textContent, tab);
        if (text.includes('Export') || text.includes('export')) {
            await tab.click();
            break;
        }
    }
    await page.waitForTimeout(500);
    
    // Select blank_template theme
    await page.select('#export-theme', 'blank_template');
    await page.waitForTimeout(500);
    
    // Dump the poster card DOM
    const dom = await page.evaluate(() => {
        const card = document.getElementById('poster-preview-card');
        if (!card) return 'Card not found';
        
        const result = {
            childCount: card.children.length,
            children: []
        };
        
        for (let i = 0; i < card.children.length; i++) {
            const child = card.children[i];
            result.children.push({
                index: i,
                tag: child.tagName,
                id: child.id,
                className: child.className,
                display: getComputedStyle(child).display,
                position: getComputedStyle(child).position,
                innerHTML_length: child.innerHTML.length,
                innerText_preview: child.innerText.substring(0, 200),
                childCount: child.children.length
            });
        }
        
        const body = document.getElementById('poster-schedule-body');
        if (body) {
            result.scheduleBodyChildren = body.children.length;
            result.scheduleBodyText = body.innerText.substring(0, 500);
        }
        
        return result;
    });
    
    console.log(JSON.stringify(dom, null, 2));
    
    await browser.close();
})();
