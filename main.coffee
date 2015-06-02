eventToPosition = (e) ->
    rect = event.target.getBoundingClientRect();
    { x: event.clientX - rect.left, y: event.clientY - rect.top }

calcPositionDiff = (p) ->
    { x: p[0].x - p[1].x, y: p[0].y - p[1].y }

window.onload = ->
    hough = new Hough()
    hough.draw()

class Hough
    constructor: (@canvas)->
        @xy_canvas = document.getElementById("xy-canvas");
        @xy_ctx = @xy_canvas.getContext("2d")

        @pq_canvas = document.getElementById("uv-canvas");
        @pq_ctx = @pq_canvas.getContext("2d")

        @width = @xy_canvas.width
        @height = @xy_canvas.height

        @xy_line = new Line(((_x, _y, x) => _x * x + _y + 1), @xy_canvas)

        @points = []
        @pq_lines = []
        for i in [1...11]
            do (i) =>
                position = { x: 10 * i, y: 10 * i }
                point = new DraggablePoint(@xy_canvas, position, 5)
                q = (x, y, p) -> -p * x + y + 1
                pq_line = new Line(q, @pq_canvas)
                point.moveBus().onValue((p) =>
                    pq_line.move(p.x, p.y)
                    @draw())
                pq_line.move(position.x, position.y)
                @pq_lines.push(pq_line)
                @points.push(point)

        mouseleave = Bacon.fromEvent(@pq_canvas, "mouseleave")
        mousemove = Bacon.fromEvent(@pq_canvas, "mousemove")
        mousemove
            .map(eventToPosition)
            .merge(mouseleave.map(null))
            .onValue((p) =>
                if p == null
                    @xy_line.hide()
                else
                    @xy_line.move(p.x, p.y)
                @draw())

    draw: ->
        @xy_ctx.fillStyle = "rgb(255, 255, 255)";
        @xy_ctx.fillRect(0, 0, @width, @height);

        @pq_ctx.fillStyle = "rgb(255, 255, 255)";
        @pq_ctx.fillRect(0, 0, @width, @height);

        hw = @width / 2
        hh = @height / 2

        for point in @points
            point.draw(@xy_ctx)

        for pq_line in @pq_lines
            pq_line.draw(@pq_ctx)

        @xy_line.draw(@xy_ctx)

class Line
    constructor: (@transform, canvas) ->
        @width = canvas.width
        @height = canvas.height
        @half_width = @width / 2
        @half_height = @height / 2
        @x = null
        @y = null

    move: (x, y) =>
        @x = x / @half_width - 1
        @y = y / @half_height - 1

    hide: () ->
        @x = null
        @y = null

    draw: (ctx) =>
        if @x == null || @y == null
            return

        ctx.beginPath()
        ctx.moveTo(0, @transform(@x, @y, -1) * @half_height)
        ctx.lineTo(@width, @transform(@x, @y, 1) * @half_height)
        ctx.stroke()

class DraggablePoint
    _dragMoveStream: (mousedown, mouseup, mousemove) ->
        mousedown
            .map(eventToPosition)
            .filter(@hittest)
            .flatMap(() =>
                mousemove
                    .map(eventToPosition)
                    .slidingWindow(2, 2)
                    .map(calcPositionDiff)
                    .takeUntil(mouseup))

    constructor: (canvas, @position, @radius) ->
        mousedown = Bacon.fromEvent(canvas, "mousedown")
        mouseup = Bacon.fromEvent(canvas, "mouseup")
        mousemove = Bacon.fromEvent(canvas, "mousemove")

        @move_bus = new Bacon.Bus()
        @_dragMoveStream(mousedown, mouseup, mousemove)
            .toProperty({ x: 0, y: 0 })
            .onValue((p) =>
                @position.x -= p.x
                @position.y -= p.y
                @move_bus.push(@position))

    hittest: (p) =>
        dx = p.x - @position.x
        dy = p.y - @position.y
        (dx ** 2 + dy ** 2) < @radius ** 2

    moveBus: () => @move_bus

    draw: (ctx) =>
      ctx.beginPath();
      ctx.arc(@position.x, @position.y, @radius, 0, Math.PI*2, false);
      ctx.stroke();

