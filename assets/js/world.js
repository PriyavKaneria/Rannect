var config = {
	percent: 0,
	lat: 0,
	lng: 0,
	segX: 28,
	segY: 12,
	isHaloVisible: true,
	isPoleVisible: true,
	autoSpin: false,
	zoom: 0,
	maxZoom: 1,
	markerThersholdZoom: 0.7,

	skipPreloaderAnimation: false,

	goToHongKong: function () {
		goTo(22.28552, 114.15769)
	},
}

var stats
var imgs
var preloader
var preloadPercent
var globeDoms
var vertices
var markerSegments = {}

var world
var worldBg
var globe
var globeContainer
var globePole
var globeHalo
var markers = []

var pixelExpandOffset = 1.5
var rX = 0
var rY = 0
var rZ = 0
var sinRX
var sinRY
var sinRZ
var cosRX
var cosRY
var cosRZ
var dragX
var dragY
var dragLat
var dragLng

var isMouseDown = false
var isTweening = false
var tick = 1

var URLS = {
	bg: "https://s3-us-west-2.amazonaws.com/s.cdpn.io/6043/css_globe_bg.jpg",
	diffuse:
		"https://s3-us-west-2.amazonaws.com/s.cdpn.io/6043/css_globe_diffuse.jpg",
	halo: "https://s3-us-west-2.amazonaws.com/s.cdpn.io/6043/css_globe_halo.png",
}

var transformStyleName = PerspectiveTransform.transformStyleName

export function init(ref) {
	world = document.querySelector(".world")
	worldBg = document.querySelector(".world-bg")
	worldBg.style.backgroundImage = "url(" + URLS.bg + ")"
	globe = document.querySelector(".world-globe")
	globeContainer = document.querySelector(".world-globe-doms-container")
	globePole = document.querySelector(".world-globe-pole")
	globeHalo = document.querySelector(".world-globe-halo")
	// globeHalo.style.backgroundImage = "url(" + URLS.halo + ")"

	regenerateGlobe()

	// var gui = new dat.GUI()
	// gui.add(config, "lat", -90, 90).listen()
	// gui.add(config, "lng", -180, 180).listen()
	// gui.add(config, "isHaloVisible")
	// gui.add(config, "isPoleVisible")
	// gui.add(config, "autoSpin")
	// gui.add(config, "goToHongKong")
	// gui.add(config, "zoom", 0, 1).listen()

	// stats = new Stats()
	// stats.domElement.style.position = "absolute"
	// stats.domElement.style.left = 0
	// stats.domElement.style.top = 0
	// document.body.appendChild(stats.domElement)

	// events
	globe.ondragstart = function () {
		return false
	}
	globe.addEventListener("mousedown", onMouseDown)
	globe.addEventListener("mousemove", onMouseMove)
	globe.addEventListener("mouseup", onMouseUp)
	globe.addEventListener("mouseleave", onMouseUp)
	globe.addEventListener("touchstart", touchPass(onMouseDown))
	globe.addEventListener("touchmove", touchPass(onMouseMove))
	globe.addEventListener("touchend", touchPass(onMouseUp))
	globe.addEventListener("wheel", onMouseScroll)

	calcMarkers()
	// loadMarkers()
	updateMarkerPositions()
	loop()
}

function updateMarkerSegments(marker, lat, lng) {
	var rtheta = ((90 - lat) * Math.PI) / 180
	var rphi = ((lng + 180) * Math.PI) / 180
	var i = 1
	while (i < vertices.length && rtheta >= vertices[i][0].theta) i++
	var j = 1
	while (j < vertices[i].length && rphi >= vertices[i][j].phi) j++
	var dtheta = rtheta - vertices[i - 1][0].theta
	var dphi = rphi - vertices[i - 1][j - 1].phi
	// console.log(lat, lng, i, j, dtheta, dphi)
	if (markerSegments[[i - 1, j - 1]]) {
		markerSegments[[i - 1, j - 1]].push({
			marker: marker,
			dtheta: dtheta,
			dphi: dphi,
		})
	} else {
		markerSegments[[i - 1, j - 1]] = [
			{
				marker: marker,
				dtheta: dtheta,
				dphi: dphi,
			},
		]
	}
}

export function calcMarkers() {
	markers = document.getElementsByClassName("world-marker")
	for (var i = 0; i < markers.length; i++) {
		var marker = markers[i]
		// var plat = 0
		// var plng = 0
		// if (marker.attributes.lat)
		// console.log(markers, marker)
		var plat = parseFloat(marker.attributes.lat?.nodeValue)
		// if (marker.attributes.lng)
		var plng = parseFloat(marker.attributes.lng?.nodeValue)
		// console.log(plat, plng)
		if (marker.attributes.lat && marker.attributes.lng) {
			updateMarkerSegments(marker, plat, plng)
		}
		// marker.classList.remove("world-marker")
		// marker.classList.add("world-marker-static")
		// marker.removeAttribute("userid")
	}
	loadMarkers()
	// console.log(markerSegments)
}

function removeAllChildNodes(parent, userid) {
	let children = parent.children
	for (let i = 0; i < children.length; i++) {
		const child = children[i]
		if (
			child.attributes.userid &&
			child.attributes.userid.nodeValue == userid
		) {
			parent.removeChild(child)
		}
	}
}

export function loadMarkers() {
	console.log("loadMarkers")
	var segY = config.segY
	var segX = config.segX
	var segHeight = Math.PI / 13.333333333333334
	var segWidth = Math.PI / 7
	for (y = 0; y <= segY; y++) {
		for (x = 0; x <= segX; x++) {
			if (markerSegments[[y, x]]) {
				markerSegments[[y, x]].forEach((markerData) => {
					var marker = markerData.marker
					// console.log(marker)
					removeAllChildNodes(
						globeDoms[x + segX * y],
						marker.attributes.userid.nodeValue
					)
					// console.log(globeDoms[x + segX * y])
					globeDoms[x + segX * y].appendChild(marker)
					marker.style.position = "absolute"
					marker.style.left = (markerData.dphi / segWidth) * 100 + "%"
					marker.style.top = (markerData.dtheta / segHeight) * 100 + "%"
				})
			}
		}
	}
}

export function setAutoSpin(checked) {
	config.autoSpin = checked
}

function getRegionOfMarker(marker, parent) {}

function updateMarkerPositions() {
	// console.log("updateMarkerPositions")
	markers = document.getElementsByClassName("world-marker")
	// console.log(markers)
	for (const marker of markers) {
		// console.log(marker.attributes.userid.nodeValue)
		if (!marker) continue
		var mrkr = document.getElementById(
			"marker-" + marker.attributes.userid.nodeValue
		)
		if (!mrkr) continue
		mrkrRect = marker.getBoundingClientRect()
		// console.log(mrkrRect)
		mrkr.style.left = mrkrRect.left + "px"
		mrkr.style.top = mrkrRect.top + "px"
	}
	// console.log(config.zoom)
	// debugger
}

function touchPass(func) {
	return function (evt) {
		evt.preventDefault()
		func.call(this, {
			pageX: evt.changedTouches[0].pageX,
			pageY: evt.changedTouches[0].pageY,
		})
	}
}

function onMouseDown(evt) {
	isMouseDown = true
	dragX = evt.pageX
	dragY = evt.pageY
	dragLat = config.lat
	dragLng = config.lng
}

function onMouseMove(evt) {
	if (isMouseDown) {
		var dX = evt.pageX - dragX
		var dY = evt.pageY - dragY
		config.lat = clamp(dragLat + dY * 0.5, -90, 90)
		config.lng = clampLng(dragLng - dX * 0.5, -180, 180)
	}
}

function onMouseUp(evt) {
	if (isMouseDown) {
		isMouseDown = false
	}
}

function onMouseScroll(evt) {
	if (evt.deltaY > 0 && config.zoom == 0) return
	if (evt.deltaY < 0 && config.zoom == 1) return
	config.zoom += evt.deltaY * 0.0005 * -1
	config.zoom = parseFloat(config.zoom).toFixed(2)
	config.zoom = clamp(config.zoom, 0, config.maxZoom)
	config.zoom = parseFloat(config.zoom)
}

function regenerateGlobe() {
	console.log("regenerating globe")
	var dom, domStyle
	var x, y
	globeDoms = []
	while ((dom = globeContainer.firstChild)) {
		globeContainer.removeChild(dom)
	}

	var segX = config.segX
	var segY = config.segY
	var diffuseImgBackgroundStyle = "url(" + URLS.diffuse + ")"
	var segWidth = (1600 / segX) | 0
	var segHeight = (800 / segY) | 0

	vertices = []

	var verticesRow
	var radius = 536 / 2

	var phiStart = 0
	var phiLength = Math.PI * 2

	var thetaStart = 0
	var thetaLength = Math.PI

	for (y = 0; y <= segY; y++) {
		verticesRow = []

		for (x = 0; x <= segX; x++) {
			var u = x / segX
			var v = 0.05 + (y / segY) * (1 - 0.1)

			var vertex = {
				x:
					-radius *
					Math.cos(phiStart + u * phiLength) *
					Math.sin(thetaStart + v * thetaLength),
				y: -radius * Math.cos(thetaStart + v * thetaLength),
				z:
					radius *
					Math.sin(phiStart + u * phiLength) *
					Math.sin(thetaStart + v * thetaLength),
				phi: phiStart + u * phiLength,
				theta: thetaStart + v * thetaLength,
			}
			verticesRow.push(vertex)
		}
		vertices.push(verticesRow)
	}

	console.log(vertices)

	for (y = 0; y < segY; ++y) {
		for (x = 0; x < segX; ++x) {
			dom = document.createElement("div")
			domStyle = dom.style
			domStyle.position = "absolute"
			domStyle.width = segWidth + "px"
			domStyle.height = segHeight + "px"
			domStyle.overflow = "visible"
			domStyle[PerspectiveTransform.transformOriginStyleName] = "0 0"
			domStyle.backgroundImage = diffuseImgBackgroundStyle
			dom.perspectiveTransform = new PerspectiveTransform(
				dom,
				segWidth,
				segHeight
			)
			dom.topLeft = vertices[y][x]
			dom.topRight = vertices[y][x + 1]
			dom.bottomLeft = vertices[y + 1][x]
			dom.bottomRight = vertices[y + 1][x + 1]
			domStyle.backgroundPosition =
				-segWidth * x + "px " + -segHeight * y + "px"
			globeContainer.appendChild(dom)
			globeDoms.push(dom)
		}
	}
}

function loop() {
	requestAnimationFrame(loop)
	// stats.begin()
	render()
	// stats.end()
}

function render() {
	if (config.autoSpin && !isMouseDown && !isTweening) {
		config.lng = clampLng(config.lng - 0.1)
	}

	rX = (config.lat / 180) * Math.PI
	rY = ((clampLng(config.lng) - 270) / 180) * Math.PI

	globePole.style.display = config.isPoleVisible ? "block" : "none"
	globeHalo.style.display = config.isHaloVisible ? "block" : "none"

	var ratio = Math.pow(config.zoom, 1.5)
	pixelExpandOffset = 1.5 + ratio * -1.25
	ratio = 1 + ratio * 3
	globe.style[transformStyleName] = "scale(" + ratio + "," + ratio + ")"
	ratio = 1 + Math.pow(config.zoom, 3) * 0.3
	worldBg.style[transformStyleName] = "scale3d(" + ratio + "," + ratio + ",1)"

	transformGlobe()
	updateMarkerPositions()
}

function clamp(x, min, max) {
	return x < min ? min : x > max ? max : x
}

function clampLng(lng) {
	return ((lng + 180) % 360) - 180
}

function transformGlobe() {
	var dom, perspectiveTransform
	var x, y, v1, v2, v3, v4, vertex, verticesRow, i, len
	// console.log("tick ", tick)
	if ((tick ^= 1)) {
		sinRY = Math.sin(rY)
		sinRX = Math.sin(-rX)
		sinRZ = Math.sin(rZ)
		cosRY = Math.cos(rY)
		cosRX = Math.cos(-rX)
		cosRZ = Math.cos(rZ)

		var segX = config.segX
		var segY = config.segY

		for (y = 0; y <= segY; y++) {
			verticesRow = vertices[y]
			for (x = 0; x <= segX; x++) {
				rotate((vertex = verticesRow[x]), vertex.x, vertex.y, vertex.z)
			}
		}

		for (y = 0; y < segY; y++) {
			for (x = 0; x < segX; x++) {
				dom = globeDoms[x + segX * y]

				v1 = dom.topLeft
				v2 = dom.topRight
				v3 = dom.bottomLeft
				v4 = dom.bottomRight

				expand(v1, v2)
				expand(v2, v3)
				expand(v3, v4)
				expand(v4, v1)

				perspectiveTransform = dom.perspectiveTransform
				perspectiveTransform.topLeft.x = v1.tx
				perspectiveTransform.topLeft.y = v1.ty
				perspectiveTransform.topRight.x = v2.tx
				perspectiveTransform.topRight.y = v2.ty
				perspectiveTransform.bottomLeft.x = v3.tx
				perspectiveTransform.bottomLeft.y = v3.ty
				perspectiveTransform.bottomRight.x = v4.tx
				perspectiveTransform.bottomRight.y = v4.ty
				perspectiveTransform.hasError = perspectiveTransform.checkError()

				if (
					!(perspectiveTransform.hasError = perspectiveTransform.checkError())
				) {
					perspectiveTransform.calc()
				}
			}
		}
	} else {
		for (i = 0, len = globeDoms.length; i < len; i++) {
			perspectiveTransform = globeDoms[i].perspectiveTransform
			if (!perspectiveTransform.hasError) {
				// globeDoms[i].hidden = false
				perspectiveTransform.update()
			} else {
				perspectiveTransform.style[transformStyleName] =
					"translate3d(-8192px, 0, 0)"
				// console.log(globeDoms[i])
				// globeDoms[i].hidden = true
			}
		}
		// debugger
	}
}

export function goToUser(userid) {
	var userMarker = document.querySelectorAll(`[userid="${userid}"]`)
	if (!userMarker.length) return
	let dataMarker = userMarker[0]
	userMarker.forEach((m) => {
		if (m.attributes.lat) {
			dataMarker = m
		}
	})
	console.log(dataMarker, userMarker)
	var lat = parseFloat(dataMarker.attributes.lat?.nodeValue)
	var lng = parseFloat(dataMarker.attributes.lng?.nodeValue)
	console.log(userid, lat, lng)
	goTo(lat, lng)
}

function goTo(lat, lng) {
	var dX = lat - config.lat
	var dY = lng - config.lng
	var roughDistance = Math.sqrt(dX * dX + dY * dY)
	isTweening = true
	TweenMax.to(config, roughDistance * 0.01, {
		lat: lat,
		lng: lng,
		ease: "easeInOutSine",
	})
	TweenMax.to(config, 1, {
		delay: roughDistance * 0.01,
		zoom: 1,
		ease: "easeInOutSine",
		onComplete: function () {
			isTweening = false
		},
	})
}

function rotate(vertex, x, y, z) {
	x0 = x * cosRY - z * sinRY
	z0 = z * cosRY + x * sinRY
	y0 = y * cosRX - z0 * sinRX
	z0 = z0 * cosRX + y * sinRX

	var offset = 1 + z0 / 4000
	x1 = x0 * cosRZ - y0 * sinRZ
	y0 = y0 * cosRZ + x0 * sinRZ

	vertex.px = x1 * offset
	vertex.py = y0 * offset
}

// shameless stole and edited from threejs CanvasRenderer
function expand(v1, v2) {
	var x = v2.px - v1.px,
		y = v2.py - v1.py,
		det = x * x + y * y,
		idet

	if (det === 0) {
		v1.tx = v1.px
		v1.ty = v1.py
		v2.tx = v2.px
		v2.ty = v2.py
		return
	}

	idet = pixelExpandOffset / Math.sqrt(det)

	x *= idet
	y *= idet

	v2.tx = v2.px + x
	v2.ty = v2.py + y
	v1.tx = v1.px - x
	v1.ty = v1.py - y
}
