
window.onload = ->
    xy_canvas = document.getElementById("xy-canvas");

    hough = new Hough(xy_canvas.getContext("2d"))
    hough.draw()


class Hough
    constructor: (@canvas)->

    draw: ->
      @canvas.beginPath();
      @canvas.arc(80, 80, 5, 0, Math.PI*2, false);
      @canvas.stroke();

