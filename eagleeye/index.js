var canvas = document.getElementById('canvas');
var context = canvas.getContext('2d');

context.fillStyle = 'black';
context.font = "bold 16px Arial";
const textPadding = 10;
const distanceBetweenBoxes = 50;

let classes = [];

function drawBox({text, x, y})
{
  let padding = 10;
  let textWidth = context.measureText(text).width;

  context.strokeStyle = 'black';
  let width = textWidth + textPadding * 2;
  context.strokeRect(x, y, width + textPadding * 2, 50);
  context.fillText(text, x + padding * 2, 40);

  return width;
}

function methodCall({ offsetX, offsetY, firstBoxWidth, secondBoxWidth, methodCall })
{
  // Line under box 1
  context.beginPath();
  context.moveTo(offsetX + firstBoxWidth/2, offsetY + 50);
  context.lineTo(offsetX + firstBoxWidth/2, offsetY + 100);
  context.closePath();
  context.stroke();

  // Line under box 2
  context.beginPath();
  context.moveTo(offsetX + firstBoxWidth + distanceBetweenBoxes + secondBoxWidth/2, offsetY + 50);
  context.lineTo(offsetX + firstBoxWidth + distanceBetweenBoxes + secondBoxWidth/2, offsetY + 100);
  context.closePath();
  context.stroke();

  // Arrow
  context.beginPath();
  context.moveTo((offsetX + firstBoxWidth + distanceBetweenBoxes + secondBoxWidth/2) - 5, (offsetY + 100) - 5);
  context.lineTo(offsetX + firstBoxWidth + distanceBetweenBoxes + secondBoxWidth/2, offsetY + 100);
  context.lineTo((offsetX + firstBoxWidth + distanceBetweenBoxes + secondBoxWidth/2) - 5, (offsetY + 100) + 5);
  context.closePath();
  context.stroke();
  context.fillStyle = 'black';
  context.fill();

  // Line from box 1 to box 2
  context.beginPath();
  context.moveTo(offsetX + firstBoxWidth/2, offsetY + 100);
  context.lineTo(offsetX + firstBoxWidth + distanceBetweenBoxes + secondBoxWidth/2, offsetY + 100);
  context.closePath();
  context.stroke();

  // Method name on top of line
  let textWidth = context.measureText(methodCall).width;
  let text_position_in_line = ((offsetX + firstBoxWidth/2) + (offsetX + firstBoxWidth + distanceBetweenBoxes + secondBoxWidth/2)) / 2;
  text_position_in_line = text_position_in_line - (textWidth / 2);
  context.fillText(methodCall, text_position_in_line, offsetY + 95);
}

line1 = "Api_PanelUsersController->AddDemographicsToPanelUserService:#store"

let system = {
  process: function(line) {
    caller_class = line.split("->")[0];
    callee_class = line.split("->")[1].split(":")[0];
    method = line.split("->")[1].split(":")[1];

    width1 = drawBox({ text: caller_class, x: 10, y: 10 });
    width2 = drawBox({ text: callee_class, x: width1 + distanceBetweenBoxes, y: 10 });
    methodCall({ offsetX: 10, offsetY: 10, firstBoxWidth: width1, secondBoxWidth: width2, methodCall: method });
  }
}

system.process(line1);
