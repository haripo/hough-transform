
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

        @points = []
        for i in [1...10]
            position = { x: 10 * i, y: 10 * i }
            point = new DraggablePoint(@xy_canvas, position, 5)
            point.moveBus().onValue(() =>
                @draw()
            )
            @points.push(point)

    draw: ->
        @xy_ctx.fillStyle = "rgb(255, 255, 255)";
        @xy_ctx.fillRect(0, 0, @width, @height);

        @pq_ctx.fillStyle = "rgb(255, 255, 255)";
        @pq_ctx.fillRect(0, 0, @width, @height);

        for point in @points
            point.draw(@xy_ctx)

            # draw line on uv-canvas
            px = point.position.x / (@width / 2) - 1
            py = point.position.y / (@height / 2) - 1
            q = (p) -> -p * px + py + 1
            @pq_ctx.beginPath()
            @pq_ctx.moveTo(0, q(-1) * (@height / 2))
            @pq_ctx.lineTo(@width, q(1) * (@height / 2))
            @pq_ctx.stroke()

class DraggablePoint
    constructor: (canvas, @position, @radius) ->
        mousedown = Bacon.fromEvent(canvas, "mousedown")
        mouseup = Bacon.fromEvent(canvas, "mouseup")

        deltas = mousedown
            .map((e) => @eventToPosition(e))
            .filter((p) => @hittest(p))
            .flatMap(() =>
                Bacon.fromEvent(canvas, "mousemove")
                    .map((e) => @eventToPosition(e))
                    .slidingWindow(2, 2)
                    .map((p) -> {
                        x: p[0].x - p[1].x,
                        y: p[0].y - p[1].y
                    })
                    .takeUntil(mouseup)
        )

        @move_bus = new Bacon.Bus()
        deltas.toProperty({ x: 0, y: 0 }).onValue((p) =>
            @position.x -= p.x
            @position.y -= p.y
            @move_bus.push(@position)
        )

    eventToPosition: (e) ->
        rect = event.target.getBoundingClientRect();
        { x: event.clientX - rect.left, y: event.clientY - rect.top }

    hittest: (p) ->
        ((p.x - @position.x) ** 2 + (p.y - @position.y) ** 2) <
            @radius ** 2

    moveBus: () -> @move_bus

    draw: (ctx) ->
      ctx.beginPath();
      ctx.arc(@position.x, @position.y, @radius, 0, Math.PI*2, false);
      ctx.stroke();


