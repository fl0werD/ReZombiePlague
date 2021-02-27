#if defined _util_tempentities_included
	#endinput
#endif

#define _util_tempentities_included

/**
 * You have to call message_begin[/_f] before call stocks.
 */

stock TE_BeamPoints(Float:start[3], Float:end[3], spriteIndex, startingFrame, frameRate, life, lineWidth, noiseAmplitude, color[3], brightness, scrollSpeed)
{
	write_byte(TE_BEAMPOINTS);
	write_coord_f(start[0]); // startposition.x
	write_coord_f(start[1]); // startposition.y
	write_coord_f(start[2]); // startposition.z
	write_coord_f(end[0]); // endposition.x
	write_coord_f(end[1]); // endposition.y
	write_coord_f(end[2]); // endposition.z
	write_short(spriteIndex); // sprite index
	write_byte(startingFrame); // starting frame
	write_byte(frameRate); // frame rate in 0.1's
	write_byte(life); // life in 0.1's
	write_byte(lineWidth); // line width in 0.1's
	write_byte(noiseAmplitude); // noise amplitude in 0.01's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(brightness); // brightness
	write_byte(scrollSpeed); // scroll speed in 0.1's
	message_end();
}

stock TE_BeamEntPoint(startEntity, Float:end[3], spriteIndex, startingFrame, frameRate, life, lineWidth, noiseAmplitude, color[3], brightness, scrollSpeed)
{
	write_byte(TE_BEAMENTPOINT);
	write_short(startEntity); // start entity
	write_coord_f(end[0]); // endposition.x
	write_coord_f(end[1]); // endposition.y
	write_coord_f(end[2]); // endposition.z
	write_short(spriteIndex); // sprite index
	write_byte(startingFrame); // starting frame
	write_byte(frameRate); // frame rate in 0.1's
	write_byte(life); // life in 0.1's
	write_byte(lineWidth); // line width in 0.1's
	write_byte(noiseAmplitude); // noise amplitude in 0.01's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(brightness); // brightness
	write_byte(scrollSpeed); // scroll speed in 0.1's
	message_end();
}

stock TE_GunShot(Float:position[3])
{
	write_byte(TE_GUNSHOT);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	message_end();
}

stock TE_Explosion(Float:position[3], spriteIndex, scale, frameRate, flags)
{
	write_byte(TE_EXPLOSION);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_short(spriteIndex); // sprite index
	write_byte(scale); // scale in 0.1's
	write_byte(frameRate); // framerate
	write_byte(flags); // flags
	message_end();
}

stock TE_TarExplosion(Float:position[3])
{
	write_byte(TE_TAREXPLOSION);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	message_end();
}

stock TE_Smoke(Float:position[3], spriteIndex, scale, frameRate)
{
	write_byte(TE_SMOKE);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_short(spriteIndex); // sprite index
	write_byte(scale); // scale in 0.1's
	write_byte(frameRate); // framerate
	message_end();
}

stock TE_Tracer(Float:start[3], Float:end[3])
{
	write_byte(TE_TRACER);
	write_coord_f(start[0]); // startposition.x
	write_coord_f(start[1]); // startposition.y
	write_coord_f(start[2]); // startposition.z
	write_coord_f(end[0]); // endposition.x
	write_coord_f(end[1]); // endposition.y
	write_coord_f(end[2]); // endposition.z
	message_end();
}

stock TE_Lighting(Float:start[3], Float:end[3], life, width, amplitude, spriteIndex)
{
	write_byte(TE_LIGHTNING);
	write_coord_f(start[0]); // startposition.x
	write_coord_f(start[1]); // startposition.y
	write_coord_f(start[2]); // startposition.z
	write_coord_f(end[0]); // endposition.x
	write_coord_f(end[1]); // endposition.y
	write_coord_f(end[2]); // endposition.z
	write_byte(life); // life in 0.1's
	write_byte(width); // width in 0.1's
	write_byte(amplitude); // amplitude in 0.01's
	write_short(spriteIndex); // sprite model index
	message_end();
}

stock TE_BeamEnts(startEntity, endEntity, spriteIndex, startingFrame, frameRate, life, lineWidth, noiseAmplitude, color[3], brightness, scrollSpeed)
{
	write_byte(TE_BEAMENTS);
	write_short(startEntity); // start entity
	write_short(endEntity); // end entity
	write_short(spriteIndex); // sprite index
	write_byte(startingFrame); // starting frame
	write_byte(frameRate); // frame rate in 0.1's
	write_byte(life); // life in 0.1's
	write_byte(lineWidth); // line width in 0.1's
	write_byte(noiseAmplitude); // noise amplitude in 0.01's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(brightness); // brightness
	write_byte(scrollSpeed); // scroll speed in 0.1's
	message_end();
}

stock TE_Sparks(Float:position[3])
{
	write_byte(TE_SPARKS);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	message_end();
}

stock TE_LavaSplash(Float:position[3])
{
	write_byte(TE_LAVASPLASH);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	message_end();
}

stock TE_Teleport(Float:position[3])
{
	write_byte(TE_TELEPORT);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	message_end();
}

stock TE_Explosion2(Float:position[3], startingColor, numColors)
{
	write_byte(TE_EXPLOSION2);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_byte(startingColor); // starting color
	write_byte(numColors); // num colors
	message_end();
}

stock TE_BSPDecal(Float:position[3], textureIndex, entityIndex, modelIndex)
{
	write_byte(TE_BSPDECAL);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_short(textureIndex); // texture index of precached decal texture name)
	write_short(entityIndex); // entity index
	if (entityIndex != 0)
		write_short(modelIndex); // index of model of above entity only included if previous short is non-zero (not the world)
	message_end();
}

stock TE_Implosion(Float:position[3], radius, count, life)
{
	write_byte(TE_IMPLOSION);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_byte(radius); // radius
	write_byte(count); // count
	write_byte(life); // life in 0.1's
	message_end();
}

stock TE_SpriteTrail(Float:start[3], Float:end[3], spriteIndex, count, life, scale, velocity, randomness)
{
	write_byte(TE_SPRITETRAIL);
	write_coord_f(start[0]); // startposition.x
	write_coord_f(start[1]); // startposition.y
	write_coord_f(start[2]); // startposition.z
	write_coord_f(end[0]); // endposition.x
	write_coord_f(end[1]); // endposition.y
	write_coord_f(end[2]); // endposition.z
	write_short(spriteIndex); // sprite index
	write_byte(count); // count
	write_byte(life); // life in 0.1's
	write_byte(scale); // scale in 0.1's
	write_byte(velocity); // velocity along vector in 10's
	write_byte(randomness); // randomness of velocity in 10's
	message_end();
}

stock TE_Sprite(Float:position[3], spriteIndex, scale, brightness)
{
	write_byte(TE_SPRITE);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_short(spriteIndex); // sprite index
	write_byte(scale); // scale in 0.1's
	write_byte(brightness); // brightness
	message_end();
}

stock TE_BeamSprite(Float:start[3], Float:end[3], beamSpriteIndex, endSpriteIndex)
{
	write_byte(TE_BEAMSPRITE);
	write_coord_f(start[0]); // startposition.x
	write_coord_f(start[1]); // startposition.y
	write_coord_f(start[2]); // startposition.z
	write_coord_f(end[0]); // endposition.x
	write_coord_f(end[1]); // endposition.y
	write_coord_f(end[2]); // endposition.z
	write_short(beamSpriteIndex); // beam sprite index
	write_short(endSpriteIndex); // end sprite index
	message_end();
}

stock TE_BeamTorus(Float:position[3], Float:axis[3], spriteIndex, startingFrame, frameRate, life, lineWidth, noiseAmplitude, color[3], brightness, scrollSpeed)
{
	write_byte(TE_BEAMTORUS);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(axis[0]); // axis.x
	write_coord_f(axis[1]); // axis.y
	write_coord_f(axis[2]); // axis.z
	write_short(spriteIndex); // sprite index
	write_byte(startingFrame); // starting frame
	write_byte(frameRate); // frame rate in 0.1's
	write_byte(life); // life in 0.1's
	write_byte(lineWidth); // line width in 0.1's
	write_byte(noiseAmplitude); // noise amplitude in 0.01's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(brightness); // brightness
	write_byte(scrollSpeed); // scroll speed in 0.1's
	message_end();
}

stock TE_BeamDisk(Float:position[3], Float:axis[3], spriteIndex, startingFrame, frameRate, life, lineWidth, noiseAmplitude, color[3], brightness, scrollSpeed)
{
	write_byte(TE_BEAMDISK);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(axis[0]); // axis.x
	write_coord_f(axis[1]); // axis.y
	write_coord_f(axis[2]); // axis.z
	write_short(spriteIndex); // sprite index
	write_byte(startingFrame); // starting frame
	write_byte(frameRate); // frame rate in 0.1's
	write_byte(life); // life in 0.1's
	write_byte(lineWidth); // line width in 0.1's
	write_byte(noiseAmplitude); // noise amplitude in 0.01's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(brightness); // brightness
	write_byte(scrollSpeed); // scroll speed in 0.1's
	message_end();
}

stock TE_BeamCylinder(Float:position[3], Float:axis[3], spriteIndex, startingFrame, frameRate, life, lineWidth, noiseAmplitude, color[3], brightness, scrollSpeed)
{
	write_byte(TE_BEAMCYLINDER);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(axis[0]); // axis.x
	write_coord_f(axis[1]); // axis.y
	write_coord_f(axis[2]); // axis.z
	write_short(spriteIndex); // sprite index
	write_byte(startingFrame); // starting frame
	write_byte(frameRate); // frame rate in 0.1's
	write_byte(life); // life in 0.1's
	write_byte(lineWidth); // line width in 0.1's
	write_byte(noiseAmplitude); // noise amplitude in 0.01's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(brightness); // brightness
	write_byte(scrollSpeed); // scroll speed in 0.1's
	message_end();
}

stock TE_BeamFollow(entity, spriteIndex, life, lineWidth, color[3], brightness)
{
	write_byte(TE_BEAMFOLLOW);
	write_short(entity); // entity:attachment to follow
	write_short(spriteIndex); // sprite index
	write_byte(life); // life in 0.1's
	write_byte(lineWidth); // line width in 0.1's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(brightness); // brightness
	message_end();
}

stock TE_GlowSprite(Float:position[3], modelIndex, scale, size, brightness)
{
	write_byte(TE_GLOWSPRITE);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_short(modelIndex); // model index
	write_byte(scale); // scale * 10
	write_byte(size); // size
	write_byte(brightness); // brightness
	message_end();
}

stock TE_BeamRing(startEntity, endEntity, spriteIndex, startingFrame, frameRate, life, lineWidth, noiseAmplitude, color[3], brightness, scrollSpeed)
{
	write_byte(TE_BEAMRING);
	write_short(startEntity); // start entity
	write_short(endEntity); // end entity
	write_short(spriteIndex); // sprite index
	write_byte(startingFrame); // starting frame
	write_byte(frameRate); // frame rate in 0.1's
	write_byte(life); // life in 0.1's
	write_byte(lineWidth); // line width in 0.1's
	write_byte(noiseAmplitude); // noise amplitude in 0.01's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(brightness); // brightness
	write_byte(scrollSpeed); // scroll speed in 0.1's
	message_end();
}

stock TE_StreakSplash(Float:start[3], Float:vector[3], color, count, baseSpeed, randomVelocity)
{
	write_byte(TE_STREAK_SPLASH);
	write_coord_f(start[0]); // startposition.x
	write_coord_f(start[1]); // startposition.y
	write_coord_f(start[2]); // startposition.z
	write_coord_f(vector[0]); // vector.x
	write_coord_f(vector[1]); // vector.y
	write_coord_f(vector[2]); // vector.z
	write_byte(color); // color
	write_short(count); // count
	write_short(baseSpeed); // base speed
	write_short(randomVelocity); // random velocity
	message_end();
}

stock TE_DLight(Float:position[3], radius, color[3], life, decayRate)
{
	write_byte(TE_DLIGHT);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_byte(radius); // radius in 10's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(life); // life in 10's
	write_byte(decayRate); // decay rate in 10's
	message_end();
}

stock TE_ELight(entity, Float:position[3], Float:radius, color[3], life, decayRate)
{
	write_byte(TE_ELIGHT);
	write_short(entity); // entity: attachment to follow
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(radius); // radius
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	write_byte(life); // life in 0.1's
	write_coord_f(decayRate); // decay rate
	message_end();
}

stock TE_TextMssage(channel, x, y, effect, textColor[3], textAlpha, effectColor[3], effectAlpha, fadeIn, fadeOut, holdTime, fxTime, text[])
{
	write_byte(TE_TEXTMESSAGE);
	write_byte(channel); // channel
	write_short(x); // x -1 = center
	write_short(y); // y -1 = center
	write_byte(effect); // effect: 0 = fade in/fade out, 1 is flickery credits, 2 is write out (training room)
	write_byte(textColor[0]); // red - text color
	write_byte(textColor[1]); // green
	write_byte(textColor[2]); // blue
	write_byte(textAlpha); // alpha
	write_byte(effectColor[0]); // red - effect color
	write_byte(effectColor[0]); // green
	write_byte(effectColor[0]); // blue
	write_byte(effectAlpha); // alpha
	write_short(fadeIn); // fadein time
	write_short(fadeOut); // fadeout time
	write_short(holdTime); // hold time
	if (effect == 2)
		write_short(fxTime); // fxtime: time the highlight lags behing the leading text in effect 2
	write_string(text) // 512 chars max string size
	message_end();
}

stock TE_Line(Float:start[3], Float:end[3], life, color[3])
{
	write_byte(TE_LINE);
	write_coord_f(start[0]); // startposition.x
	write_coord_f(start[1]); // startposition.y
	write_coord_f(start[2]); // startposition.z
	write_coord_f(end[0]); // endposition.x
	write_coord_f(end[1]); // endposition.y
	write_coord_f(end[2]); // endposition.z
	write_short(life); // life in 0.1's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	message_end();
}

stock TE_Box(Float:boxMins[3], Float:boxMaxs[3], life, color[3])
{
	write_byte(TE_BOX);
	write_coord_f(boxMins[0]); // boxmins.x
	write_coord_f(boxMins[1]); // boxmins.y
	write_coord_f(boxMins[2]); // boxmins.z
	write_coord_f(boxMaxs[0]); // boxmaxs.x
	write_coord_f(boxMaxs[1]); // boxmaxs.y
	write_coord_f(boxMaxs[2]); // boxmaxs.z
	write_short(life); // life in 0.1's
	write_byte(color[0]); // red
	write_byte(color[1]); // green
	write_byte(color[2]); // blue
	message_end();
}

stock TE_KillBeam(entity)
{
	write_byte(TE_KILLBEAM);
	write_short(entity); // entity
	message_end();
}

stock TE_LargeFunnel(Float:position[3], spriteIndex, flags)
{
	write_byte(TE_LARGEFUNNEL);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_short(spriteIndex); // sprite index
	write_short(flags); // flags
	message_end();
}

stock TE_BloodStream(Float:position[3], Float:vector[3], color, speed)
{
	write_byte(TE_BLOODSTREAM);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(vector[0]); // vector.x
	write_coord_f(vector[1]); // vector.y
	write_coord_f(vector[2]); // vector.z
	write_byte(color); // color
	write_byte(speed); // speed
	message_end();
}

stock TE_ShowLine(Float:start[3], Float:end[3])
{
	write_byte(TE_SHOWLINE);
	write_coord_f(start[0]); // startposition.x
	write_coord_f(start[1]); // startposition.y
	write_coord_f(start[2]); // startposition.z
	write_coord_f(end[0]); // endposition.x
	write_coord_f(end[1]); // endposition.y
	write_coord_f(end[2]); // endposition.z
	message_end();
}

stock TE_Blood(Float:position[3], Float:vector[3], color, speed)
{
	write_byte(TE_BLOOD);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(vector[0]); // vector.x
	write_coord_f(vector[1]); // vector.y
	write_coord_f(vector[2]); // vector.z
	write_byte(color); // color
	write_byte(speed); // speed
	message_end();
}

stock TE_Decal(Float:position[3], textureIndex, entityIndex)
{
	write_byte(TE_DECAL);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_byte(textureIndex); // texture index of precached decal texture name
	write_short(entityIndex); // entity index
	message_end();
}

stock TE_Fizz(entity, spriteIndex, density)
{
	write_byte(TE_FIZZ);
	write_short(entity); // entity
	write_short(spriteIndex); // sprite index
	write_byte(density); // density
	message_end();
}

stock TE_Model(Float:position[3], Float:velocity[3], initialYaw, modelIndex, bounceSoundType, life)
{
	write_byte(TE_MODEL);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(velocity[0]); // velocity.x
	write_coord_f(velocity[1]); // velocity.y
	write_coord_f(velocity[2]); // velocity.z
	write_angle(initialYaw); // initial yaw
	write_short(modelIndex); // model index
	write_byte(bounceSoundType); // bounce sound type
	write_byte(life); // life in 0.1's
	message_end();
}

stock TE_ExplodeModel(Float:origin[3], Float:velocity[3], modelIndex, count, life)
{
	write_byte(TE_EXPLODEMODEL);
	write_coord_f(origin[0]); // origin.x
	write_coord_f(origin[1]); // origin.y
	write_coord_f(origin[2]); // origin.z
	write_coord_f(velocity[0]); // velocity.x
	write_coord_f(velocity[1]); // velocity.y
	write_coord_f(velocity[2]); // velocity.z
	write_short(modelIndex); // model index
	write_short(count); // count
	write_byte(life); // life in 0.1's
	message_end();
}

stock TE_BreakModel(Float:position[3], Float:size[3], Float:velocity[3], randomVelocity, modelIndex, count, life, flags)
{
	write_byte(TE_BREAKMODEL);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(size[0]); // size.x
	write_coord_f(size[1]); // size.y
	write_coord_f(size[2]); // size.z
	write_coord_f(velocity[0]); // velocity.x
	write_coord_f(velocity[1]); // velocity.y
	write_coord_f(velocity[2]); // velocity.z
	write_byte(randomVelocity); // random velocity in 10's
	write_short(modelIndex); // sprite or model index
	write_byte(count); // count
	write_byte(life); // life in 0.1 secs
	write_byte(flags); // flags
	message_end();
}

stock TE_GunShotDecal(Float:position[3], entityIndex, decalNumber)
{
	write_byte(TE_GUNSHOTDECAL);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_short(entityIndex); // entity index
	write_byte(decalNumber); // decal number
	message_end();
}

stock TE_SpriteSpray(Float:position[3], Float:velocity[3], spriteIndex, count, speed, noise)
{
	write_byte(TE_SPRITE_SPRAY);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(velocity[0]); // velocity.x
	write_coord_f(velocity[1]); // velocity.y
	write_coord_f(velocity[2]); // velocity.z
	write_short(spriteIndex); // sprite index
	write_byte(count); // count
	write_byte(speed); // speed
	write_byte(noise); // noise
	message_end();
}

stock TE_ArmorRicochet(Float:position[3], scale)
{
	write_byte(TE_ARMOR_RICOCHET);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_byte(scale); // scale in 0.1's
	message_end();
}

stock TE_PlayerDecal(playerindex, Float:position[3], entity, decalNumber)
{
	write_byte(TE_PLAYERDECAL);
	write_byte(playerindex); // playerindex
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_short(entity); // entity
	write_byte(decalNumber); // decal number
	message_end();
}

stock TE_Bubbles(Float:positionMin[3], Float:positionMax[3], Float:height, modelIndex, count, speed)
{
	write_byte(TE_BUBBLES);
	write_coord_f(positionMin[0]); // position.x (min start position)
	write_coord_f(positionMin[1]); // position.y
	write_coord_f(positionMin[2]); // position.z
	write_coord_f(positionMax[0]); // position.x (max start position)
	write_coord_f(positionMax[1]); // position.y
	write_coord_f(positionMax[2]); // position.z
	write_coord_f(height); // float height
	write_short(modelIndex); // model index
	write_byte(count); // count
	write_coord_f(speed); // speed
	message_end();
}

stock TE_BubbleTrail(Float:positionMin[3], Float:positionMax[3], Float:height, modelIndex, count, speed)
{
	write_byte(TE_BUBBLETRAIL);
	write_coord_f(positionMin[0]); // position.x (min start position)
	write_coord_f(positionMin[1]); // position.y
	write_coord_f(positionMin[2]); // position.z
	write_coord_f(positionMax[0]); // position.x (max start position)
	write_coord_f(positionMax[1]); // position.y
	write_coord_f(positionMax[2]); // position.z
	write_coord_f(height); // float height
	write_short(modelIndex); // model index
	write_byte(count); // count
	write_coord_f(speed); // speed
	message_end();
}

stock TE_BloodSprite(Float:position[3], sprite1Index, sprite2Index, color, scale)
{
	write_byte(TE_BLOODSPRITE);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_short(sprite1Index); // sprite1 index
	write_short(sprite2Index); // sprite2 index
	write_byte(color); // color
	write_byte(scale); // scale
	message_end();
}

stock TE_WorldDecal(Float:position[3], textureIndex)
{
	write_byte(TE_WORLDDECAL);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_byte(textureIndex); // texture index of precached decal texture name
	message_end();
}

stock TE_WorldDecalHigh(Float:position[3], textureIndex)
{
	write_byte(TE_WORLDDECALHIGH);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_byte(textureIndex); // texture index of precached decal texture name - 256
	message_end();
}

stock TE_DecalHigh(Float:position[3], textureIndex, entityIndex)
{
	write_byte(TE_DECALHIGH);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_byte(textureIndex); // txture index of precached decal texture name - 256)
	write_short(entityIndex); // entity index
	message_end();
}

stock TE_Projectile(Float:position[3], Float:velocity[3], modelIndex, life, owner)
{
	write_byte(TE_PROJECTILE);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(velocity[0]); // velocity.x
	write_coord_f(velocity[1]); // velocity.y
	write_coord_f(velocity[2]); // velocity.z
	write_short(modelIndex); // modelindex
	write_byte(life); // life
	write_byte(owner); // owner: projectile won't collide with owner (if owner == 0, projectile will hit any client)
	message_end();
}

stock TE_Spray(Float:position[3], direction[3], modelIndex, count, speed, noise, renderMode)
{
	write_byte(TE_SPRAY);
	write_coord_f(position[0]); // position.x
	write_coord_f(position[1]); // position.y
	write_coord_f(position[2]); // position.z
	write_coord_f(direction[0]); // direction.x
	write_coord_f(direction[1]); // direction.y
	write_coord_f(direction[2]); // direction.z
	write_short(modelIndex); // modelindex
	write_byte(count); // count
	write_byte(speed); // speed
	write_byte(noise); // noise
	write_byte(renderMode); // rendermode
	message_end();
}

stock TE_PlayerSprites(playerNum, spriteIndex, count, variance)
{
	write_byte(TE_PLAYERSPRITES);
	write_short(playerNum); // playernum
	write_short(spriteIndex); // sprite modelindex
	write_byte(count); // count
	write_byte(variance); // variance (0 = no variance in size) (10 = 10% variance in size)
	message_end();
}

stock TE_ParticleBurst(Float:origin[3], radius, particleColor, duration)
{
	write_byte(TE_PARTICLEBURST);
	write_coord_f(origin[0]); // origin
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_short(radius); // radius
	write_byte(particleColor); // particle color
	write_byte(duration); // duration * 10 (will be randomized a bit)
	message_end();
}

stock TE_FireField(Float:origin[3], radius, modelIndex, count, flags, duration)
{
	write_byte(TE_FIREFIELD);
	write_coord_f(origin[0]); // origin
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	write_short(radius); // radius (fire is made in a square around origin. -radius, -radius to radius, radius)
	write_short(modelIndex); // modelindex
	write_byte(count); // count
	write_byte(flags); // flags
	write_byte(duration); // duration (in seconds) * 10 (will be randomized a bit)
	message_end();
}

stock TE_PlayerAttachment(entityIndex, verticalOffset, modelIndex, life)
{
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(entiyIndex); // entity index of player
	write_coord_f(verticalOffset); // vertical offset (attachment origin.z = player origin.z + vertical offset)
	write_short(modelIndex); // model index
	write_short(life); // life * 10
	message_end();
}

stock TE_KillPlayerAttachments(entityIndex)
{
	write_byte(TE_KILLPLAYERATTACHMENTS);
	write_byte(entityIndex); // entity index of player
	message_end();
}

stock TE_MultiGunShot(Float:origin[3], Float:direction[3], xNoise, yNoise, count, textureIndex)
{
	write_byte(TE_MULTIGUNSHOT);
	write_coord_f(origin[0]); // origin.x
	write_coord_f(origin[1]); // origin.y
	write_coord_f(origin[2]); // origin.z
	write_coord_f(direction[0]); // direction.x
	write_coord_f(direction[1]); // direction.y
	write_coord_f(direction[2]); // direction.z
	write_coord_f(xNoise); // x noise * 100
	write_coord_f(yNoise); // y noise * 100
	write_byte(count); // count
	write_byte(textureIndex); // bullethole decal texture index
	message_end();
}

stock TE_UserTracer(Float:origin[3], Float:velocity[3], life, color, length)
{
	write_byte(TE_USERTRACER);
	write_coord_f(origin[0]); // origin.x
	write_coord_f(origin[1]); // origin.y
	write_coord_f(origin[2]); // origin.z
	write_coord_f(velocity[0]); // velocity.x
	write_coord_f(velocity[1]); // velocity.y
	write_coord_f(velocity[2]); // velocity.z
	write_byte(life); // life * 10
	write_byte(color); // color: this is an index into an array of color vectors in the engine
	write_byte(length); // length * 10
	message_end();
}
