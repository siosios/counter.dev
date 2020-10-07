////
//// DO NOT DEPLOY
//// DO NOT DEPLOY
//// DO NOT DEPLOY
/// LOTS OF HTML INJECTION VULNERABILITIES!!
///




class BaseTable extends HTMLElement {
    constructor() {
        super()
        this.attachShadow({
            mode: "open"
        });
        this.shadowRoot.innerHTML = "No data provided"
    }

    tableRow(key, value) {
        return [key, value, this.percentRepr(value)]
    }

    percentRepr(value) {
        var percentRepr = Math.round(value / this.arrayTotal * 100) + '%'
        if (percentRepr === '0%') {
            percentRepr = '<1%'
        }
        return percentRepr
    }

    get tableHeader() {
        return [this.tableHeaderFst, "Visitors", '%']
    }


    set entries(entries) {

            var array = Object.entries(entries).sort((a, b) => (b[1] - a[1]))
            this.arrayTotal = array.map(a => a[1]).reduce((a, b) => a + b)

            if (array.length === 0) {
                this.shadowRoot.innerHTML = NO_DATA_HTML
                return
            }

            // ESCAPE XXXXXXXXXXXXXXXXXXXXXXXXXXXX SECURITY 
            this.shadowRoot.innerHTML = `
                <table>
                  ${this.tableHeader ? this.tableHeader.map(val => `<th>${val}</th>`).join(''):''}
                  ${array.map(entr => `
                  <tr>
                      ${this.tableRow(...entr).map(val => `<td>${val}</td>`).join('')}
                  </tr>
                  `
                  ).join('')}
                <table>`

    }
}


customElements.define('counter-languages',
        class extends BaseTable {
            tableHeaderFst = "Language"
        }
)

customElements.define('counter-screens',
        class extends BaseTable {
            tableHeaderFst = "Screen"
        }
)

customElements.define('counter-locations',
        class extends BaseTable {
            tableHeaderFst = "Location"
        }
)


customElements.define('counter-referrals',
        class extends BaseTable {
             tableHeaderFst = "referral"
             tableRow(key, value) {
                 return [this.decorateReferrer(key), value, this.percentRepr(value)]
             }
             decorateReferrer(ref){
                 return `
                     <img src="https://icons.duckduckgo.com/ip3/${ref}.ico"></img>
                     <a href="${ref}">${ref}</a>`
             }
        }
)

customElements.define('counter-countries',
        class extends BaseTable {
            tableHeaderFst = "Country"
             tableRow(key, value) {
                 return [this.decorateCountry(key), value, this.percentRepr(value)]
             }
             decorateCountry(code){
                 return `
                     <img src="/famfamfam_flags/gif/${code}.gif">
                     ${this.resolveCountry(code)}</img>`
             }
             resolveCountry(code) {
                 // hidden jqvmap dependency
                 var entry = JQVMap.maps["world_en"].paths[code]
                 if (code === "us") {
                     return "USA"
                 }
                 if (entry) {
                     return entry["name"]
                 } else {
                     return "Unknown"
                 }
             }
        }
)